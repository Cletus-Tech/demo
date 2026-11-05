<?php

namespace App\Http\Controllers;

use App\Models\BrokerServiceRequest;
use App\Models\BrokerAuditLog;
use App\Models\BrokerTransaction;
use App\Models\BrokerPosition;
use App\Models\BrokerWallet;
use App\Models\BrokerLedgerEntry;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Validation\Rule;

class AdminController
{
    private function guard(Request $request): void
    {
        abort_unless(in_array($request->user()->role ?? 'user', ['admin','superadmin'], true), 403);
        abort_unless(($request->user()->account_status ?? 'active') === 'active', 403);
    }

    public function index(Request $request)
    {
        $this->guard($request);
        $users=User::query()->latest()->limit(200)->get(['id','name','email','role','account_status','created_at']);
        $requests=BrokerServiceRequest::query()->latest()->limit(200)->get();
        $transactions=BrokerTransaction::query()->latest()->limit(100)->get();
        $positions=BrokerPosition::query()->latest()->limit(100)->get();
        $wallets=BrokerWallet::query()->latest()->limit(100)->get();
        $ledger=BrokerLedgerEntry::query()->latest('created_at')->limit(200)->get();
        $auditLogs=BrokerAuditLog::query()->latest('created_at')->limit(200)->get();
        return view('admin',compact('users','requests','transactions','positions','wallets','ledger','auditLogs'));
    }

    public function updateUser(Request $request, User $user)
    {
        $this->guard($request);
        $data=$request->validate([
            'role'=>['required',Rule::in(['user','support','admin','superadmin'])],
            'account_status'=>['required',Rule::in(['active','suspended'])],
        ]);
        $actor=$request->user();
        abort_if($actor->id===$user->id && $data['role']!==($user->role ?? 'user'),422,'You cannot change your own role.');
        if (($actor->role ?? 'user') !== 'superadmin') {
            abort_unless($data['role'] === ($user->role ?? 'user'),403,'Only a superadmin can change roles.');
            abort_unless(($user->role ?? 'user') === 'user',403,'Only ordinary user accounts can be updated by an admin.');
        }
        abort_if($actor->id===$user->id && $data['account_status']!=='active',422,'You cannot suspend your own account.');
        DB::transaction(function () use ($user, $actor, $data) {
            $oldRole = $user->role ?? 'user';
            $oldStatus = $user->account_status ?? 'active';
            $user->forceFill($data)->save();

            if ($oldRole !== $data['role']) {
                BrokerAuditLog::create([
                    'actor_id' => $actor->id,
                    'action' => 'role_changed',
                    'target_type' => 'user',
                    'target_id' => (string) $user->id,
                    'details' => ['from' => $oldRole, 'to' => $data['role']],
                ]);
            }
            if ($oldStatus !== $data['account_status']) {
                BrokerAuditLog::create([
                    'actor_id' => $actor->id,
                    'action' => 'status_changed',
                    'target_type' => 'user',
                    'target_id' => (string) $user->id,
                    'details' => ['from' => $oldStatus, 'to' => $data['account_status']],
                ]);
            }
        });
        return back()->with('status','User account updated and audited.');
    }

    public function updateService(Request $request, BrokerServiceRequest $serviceRequest)
    {
        $this->guard($request);
        $data = $request->validate([
            'status' => ['required', Rule::in(['pending', 'in_review', 'approved', 'declined', 'closed'])],
            'admin_note' => ['nullable', 'string', 'max:2000'],
        ]);
        $oldStatus = $serviceRequest->status;
        DB::transaction(function () use ($serviceRequest, $data, $oldStatus, $request) {
            $serviceRequest->update($data);
            if ($oldStatus !== $data['status']) {
                BrokerAuditLog::create([
                    'actor_id' => $request->user()->id,
                    'action' => 'service_request_status_changed',
                    'target_type' => 'service_request',
                    'target_id' => (string) $serviceRequest->id,
                    'details' => ['from' => $oldStatus, 'to' => $data['status']],
                ]);
            }
        });
        return back()->with('status','Service enquiry updated.');
    }
}