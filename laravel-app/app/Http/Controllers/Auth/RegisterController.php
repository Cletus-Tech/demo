<?php
namespace App\Http\Controllers\Auth;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
class RegisterController
{
 public function store(Request $request)
 {
  $data = $request->validate(['name'=>'required|string|max:120','email'=>'required|email|max:255|unique:users,email','password'=>'required|confirmed|min:8']);
  $user = User::create(['name'=>$data['name'],'email'=>$data['email'],'password'=>bcrypt($data['password'])]);
  Auth::login($user);
  $request->session()->regenerate();
  return redirect()->route('dashboard');
 }
}