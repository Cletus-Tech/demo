import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class AdminResultsPage extends StatefulWidget {
  const AdminResultsPage({super.key});
  @override
  State<AdminResultsPage> createState() => _AdminResultsPageState();
}

class _AdminResultsPageState extends State<AdminResultsPage> {
  final _period = TextEditingController(text: 'First Term');
  final _year = TextEditingController(text: '2026/2027');
  final _maxCa = TextEditingController(text: '40');
  final _maxExam = TextEditingController(text: '60');
  late Future<Map<String,dynamic>> _options;
  String? _classId, _subjectId, _periodId;
  String _periodStatus = 'draft';
  List<Map<String,dynamic>> _students = [];
  final Map<String,TextEditingController> _ca = {};
  final Map<String,TextEditingController> _exam = {};
  final Map<String,TextEditingController> _teacherComments = {};
  final Map<String,TextEditingController> _headComments = {};
  bool _loadingRoster=false, _saving=false;
  SupabaseClient get _db => Supabase.instance.client;

  @override
  void initState(){super.initState();_options=_loadOptions();}
  @override
  void dispose(){
    _period.dispose();_year.dispose();_maxCa.dispose();_maxExam.dispose();
    _clearFields();super.dispose();
  }
  void _clearFields(){
    for(final c in _ca.values){c.dispose();}
    for(final c in _exam.values){c.dispose();}
    for(final c in _teacherComments.values){c.dispose();}
    for(final c in _headComments.values){c.dispose();}
    _ca.clear();_exam.clear();_teacherComments.clear();_headComments.clear();
  }
  Future<Map<String,dynamic>> _loadOptions() async{
    final v=await Future.wait<dynamic>([
      _db.from('classes').select('id,name,level').eq('status','active').order('name'),
      _db.from('subjects').select('id,name').eq('status','active').order('name'),
    ]);
    final classes=List<Map<String,dynamic>>.from(v[0] as List);
    final subjects=List<Map<String,dynamic>>.from(v[1] as List);
    _classId??=classes.isEmpty?null:classes.first['id'].toString();
    _subjectId??=subjects.isEmpty?null:subjects.first['id'].toString();
    return {'classes':classes,'subjects':subjects};
  }
  Future<void> _loadRoster() async{
    if(_classId==null||_subjectId==null||_period.text.trim().isEmpty||_year.text.trim().isEmpty)return;
    setState(()=>_loadingRoster=true);_clearFields();_students=[];_periodId=null;
    try{
      final cls=await _db.from('classes').select('name,level').eq('id',_classId!).single();
      final level=(cls['level']??cls['name']).toString();
      final rows=await _db.from('students').select('id,level,status,user_id,profiles(full_name,email)')
        .eq('level',level).order('created_at');
      final period=await _db.from('result_periods').select('id,status')
        .eq('class_id',_classId!).eq('title',_period.text.trim())
        .eq('academic_year',_year.text.trim()).maybeSingle();
      _periodId=period?['id']?.toString();_periodStatus=(period?['status']??'draft').toString();
      if(_periodId!=null){
        final saved=await _db.from('results').select('student_id,ca_score,exam_score')
          .eq('period_id',_periodId!).eq('subject_id',_subjectId!);
        for(final r in saved){
          final id=r['student_id'].toString();
          _ca[id]=TextEditingController(text:(r['ca_score']??0).toString());
          _exam[id]=TextEditingController(text:(r['exam_score']??0).toString());
        }
        final cards=await _db.from('student_report_cards')
          .select('student_id,class_teacher_comment,head_teacher_comment').eq('period_id',_periodId!);
        for(final card in cards){
          final id=card['student_id'].toString();
          _teacherComments[id]=TextEditingController(text:(card['class_teacher_comment']??'').toString());
          _headComments[id]=TextEditingController(text:(card['head_teacher_comment']??'').toString());
        }
      }
      final list=List<Map<String,dynamic>>.from(rows);
      for(final r in list){
        final id=r['id'].toString();
        _ca.putIfAbsent(id,()=>TextEditingController());
        _exam.putIfAbsent(id,()=>TextEditingController());
        _teacherComments.putIfAbsent(id,()=>TextEditingController());
        _headComments.putIfAbsent(id,()=>TextEditingController());
      }
      if(mounted)setState(()=>_students=list);
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not load class register: $e')));
    }finally{if(mounted)setState(()=>_loadingRoster=false);}
  }
  Future<String> _ensurePeriod() async{
    if(_periodId!=null)return _periodId!;
    final r=await _db.from('result_periods').insert({
      'class_id':_classId,'title':_period.text.trim(),'academic_year':_year.text.trim(),
      'created_by':_db.auth.currentUser!.id,'status':'draft',
    }).select('id').single();
    _periodId=r['id'].toString();return _periodId!;
  }
  double? _value(TextEditingController c)=>c.text.trim().isEmpty?0:double.tryParse(c.text.trim());
  String _grade(double score,double max){
    if(max<=0)return '-';final p=score/max*100;
    if(p>=70)return 'A';if(p>=60)return 'B';if(p>=50)return 'C';
    if(p>=45)return 'D';if(p>=40)return 'E';return 'F';
  }
  Future<void> _save({bool release=false}) async{
    final caMax=double.tryParse(_maxCa.text.trim());
    final examMax=double.tryParse(_maxExam.text.trim());
    if(caMax==null||examMax==null||caMax<=0||examMax<=0||_students.isEmpty)return;
    final payload=<Map<String,dynamic>>[];
    for(final student in _students){
      final id=student['id'].toString();
      final ca=_value(_ca[id]!);
      final exam=_value(_exam[id]!);
      if(ca==null||exam==null||ca<0||exam<0||ca>caMax||exam>examMax){
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Check scores for ${(student['profiles']?['full_name']??'this learner').toString()}')));
        return;
      }
      payload.add({'student_id':id,'subject_id':_subjectId,'ca_score':ca,'exam_score':exam,
        'max_ca':caMax,'max_exam':examMax});
    }
    setState(()=>_saving=true);
    try{
      final periodId=await _ensurePeriod();
      for(final row in payload){row['period_id']=periodId;}
      await _db.from('results').upsert(payload,onConflict:'period_id,student_id,subject_id');
      final reportCards=_students.map((student){
        final id=student['id'].toString();
        return {
          'period_id':periodId,'student_id':id,
          'class_teacher_comment':_teacherComments[id]?.text.trim().isEmpty==true?null:_teacherComments[id]?.text.trim(),
          'head_teacher_comment':_headComments[id]?.text.trim().isEmpty==true?null:_headComments[id]?.text.trim(),
        };
      }).toList();
      await _db.from('student_report_cards').upsert(reportCards,onConflict:'period_id,student_id');
      if(release){
        await _db.rpc('release_result_period',params:{'_period_id':periodId});
        _periodStatus='published';
      }
      if(mounted){setState((){});ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content:Text(release?'Results saved and released to ${_students.length} learners.':'Scores saved for ${_students.length} learners.')));}
    }catch(e){
      if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not save results: $e')));
    }finally{if(mounted)setState(()=>_saving=false);}
  }
  Future<void> _generate(Map<String,dynamic> student) async{
    if(_periodId==null){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Save scores for this period first.')));return;}
    try{
      final profile=student['profiles'] as Map<String,dynamic>?;
      final cls=await _db.from('classes').select('name').eq('id',_classId!).single();
      final rows=await _db.from('results')
        .select('score,grade,remark,ca_score,exam_score,max_ca,max_exam,subjects(name)')
        .eq('period_id',_periodId!).eq('student_id',student['id']).order('created_at');
      if(rows.isEmpty)throw Exception('No subject results have been saved for this learner.');
      final report=await _db.from('student_report_cards')
        .select('class_teacher_comment,head_teacher_comment,days_school_open,days_present,position_in_class,next_term_begins')
        .eq('period_id',_periodId!).eq('student_id',student['id']).maybeSingle();
      final doc=pw.Document();
      final total=rows.fold<double>(0,(v,r)=>v+(double.tryParse(r['score'].toString())??0));
      final max=rows.fold<double>(0,(v,r)=>v+(double.tryParse(r['max_ca'].toString())??40)+(double.tryParse(r['max_exam'].toString())??60));
      doc.addPage(pw.MultiPage(pageFormat:PdfPageFormat.a4,margin:const pw.EdgeInsets.all(32),build:(ctx)=>[
        pw.Container(color:PdfColor.fromHex('#4A3022'),padding:const pw.EdgeInsets.all(18),
          child:pw.Column(children:[
            pw.Text('YOUNG LEARNERS TUTORIAL',style:pw.TextStyle(color:PdfColors.white,fontSize:19,fontWeight:pw.FontWeight.bold)),
            pw.SizedBox(height:4),pw.Text('EVERY CHILD CAN LEARN',style:pw.TextStyle(color:PdfColor.fromHex('#F5D58C'),fontSize:9,letterSpacing:2)),
            pw.SizedBox(height:9),pw.Text('STUDENT ACADEMIC REPORT',style:pw.TextStyle(color:PdfColors.white,fontSize:12,fontWeight:pw.FontWeight.bold)),
          ])),
        pw.SizedBox(height:16),
        pw.Table(border:pw.TableBorder.all(color:PdfColor.fromHex('#D9D0C5')),
          children:[
            pw.TableRow(children:[_info('STUDENT',(profile?['full_name']??'Learner').toString()),_info('CLASS',(cls['name']??'').toString())]),
            pw.TableRow(children:[_info('TERM',_period.text.trim()),_info('ACADEMIC YEAR',_year.text.trim())]),
          ]),
        pw.SizedBox(height:16),
        pw.TableHelper.fromTextArray(
          headers:['SUBJECT','CA','EXAM','TOTAL','GRADE','REMARK'],
          data:rows.map((r)=>[(r['subjects']?['name']??'Subject').toString(),
            '${r['ca_score']}/${r['max_ca']}','${r['exam_score']}/${r['max_exam']}',
            r['score'].toString(),(r['grade']??'-').toString(),(r['remark']??'-').toString()]).toList(),
          headerDecoration:pw.BoxDecoration(color:PdfColor.fromHex('#EBD9B8')),
          headerStyle:pw.TextStyle(fontSize:8,fontWeight:pw.FontWeight.bold),
          cellStyle:const pw.TextStyle(fontSize:8),
          cellPadding:const pw.EdgeInsets.symmetric(horizontal:5,vertical:8),
        ),
        pw.SizedBox(height:16),
        pw.Container(color:PdfColor.fromHex('#F7F3EC'),padding:const pw.EdgeInsets.all(13),
          child:pw.Row(mainAxisAlignment:pw.MainAxisAlignment.spaceBetween,children:[
            pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
              pw.Text('AGGREGATE SCORE',style:pw.TextStyle(fontSize:8,color:PdfColor.fromHex('#746D66'))),
              pw.Text('${total.toStringAsFixed(1)} / ${max.toStringAsFixed(1)}',style:pw.TextStyle(fontSize:17,fontWeight:pw.FontWeight.bold,color:PdfColor.fromHex('#4A3022'))),
            ]),
            pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.end,children:[
              pw.Text('OVERALL AVERAGE',style:pw.TextStyle(fontSize:8,color:PdfColor.fromHex('#746D66'))),
              pw.Text('${max==0?'0':(total/max*100).toStringAsFixed(1)}%',style:pw.TextStyle(fontSize:20,fontWeight:pw.FontWeight.bold,color:PdfColor.fromHex('#4A3022'))),
            ]),
          ])),
        if((report?['class_teacher_comment']??'').toString().isNotEmpty)
          pw.Padding(padding:const pw.EdgeInsets.only(top:10),child:pw.Text('CLASS TEACHER’S REMARK: ${report!['class_teacher_comment']}',style:const pw.TextStyle(fontSize:9))),
        if((report?['head_teacher_comment']??'').toString().isNotEmpty)
          pw.Padding(padding:const pw.EdgeInsets.only(top:7),child:pw.Text('CENTRE COORDINATOR’S REMARK: ${report!['head_teacher_comment']}',style:const pw.TextStyle(fontSize:9))),
        if(report?['position_in_class']!=null)
          pw.Padding(padding:const pw.EdgeInsets.only(top:7),child:pw.Text('POSITION IN CLASS: ${report!['position_in_class']}',style:const pw.TextStyle(fontSize:9))),
        pw.SizedBox(height:28),
        pw.Row(children:[
          pw.Expanded(child:pw.Column(children:[pw.Divider(),pw.Text('CLASS TEACHER',style:const pw.TextStyle(fontSize:8))])),
          pw.SizedBox(width:30),
          pw.Expanded(child:pw.Column(children:[pw.Divider(),pw.Text('CENTRE COORDINATOR',style:const pw.TextStyle(fontSize:8))])),
        ]),
        pw.SizedBox(height:16),
        pw.Center(child:pw.Text('Young Learners Tutorial • Every Child Can Learn.',style:pw.TextStyle(fontSize:8,color:PdfColor.fromHex('#746D66')))),
      ]));
      final name=(profile?['full_name']??'Learner').toString().replaceAll(RegExp(r'[^A-Za-z0-9_-]'),'_');
      await Printing.layoutPdf(name:'${name}_Result.pdf',onLayout:(format)=>doc.save());
    }catch(e){if(mounted)ScaffoldMessenger.of(context).showSnackBar(SnackBar(content:Text('Could not generate result sheet: $e')));}
  }
  pw.Widget _info(String label,String value)=>pw.Padding(padding:const pw.EdgeInsets.all(9),
    child:pw.Column(crossAxisAlignment:pw.CrossAxisAlignment.start,children:[
      pw.Text(label,style:pw.TextStyle(fontSize:7,color:PdfColor.fromHex('#746D66'),fontWeight:pw.FontWeight.bold)),
      pw.SizedBox(height:4),pw.Text(value,style:pw.TextStyle(fontSize:10,fontWeight:pw.FontWeight.bold)),
    ]));

  @override
  Widget build(BuildContext context)=>Scaffold(
    appBar:AppBar(title:const Text('Results & report cards')),
    body:FutureBuilder<Map<String,dynamic>>(future:_options,builder:(context,s){
      if(s.connectionState!=ConnectionState.done)return const Center(child:CircularProgressIndicator());
      if(s.hasError)return Center(child:Text('Could not load result setup: ${s.error}'));
      final classes=List<Map<String,dynamic>>.from(s.data?['classes']??[]);
      final subjects=List<Map<String,dynamic>>.from(s.data?['subjects']??[]);
      if(classes.isEmpty||subjects.isEmpty)return const Center(child:Text('Create an active class and subject first.'));
      return Column(children:[
        Padding(padding:const EdgeInsets.all(14),child:Column(children:[
          DropdownButtonFormField<String>(value:_classId,decoration:const InputDecoration(labelText:'Class'),
            items:classes.map((r)=>DropdownMenuItem(value:r['id'].toString(),child:Text(r['name'].toString()))).toList(),
            onChanged:_loadingRoster?null:(v)=>setState(()=>_classId=v)),
          const SizedBox(height:8),
          DropdownButtonFormField<String>(value:_subjectId,decoration:const InputDecoration(labelText:'Subject'),
            items:subjects.map((r)=>DropdownMenuItem(value:r['id'].toString(),child:Text(r['name'].toString()))).toList(),
            onChanged:_loadingRoster?null:(v)=>setState(()=>_subjectId=v)),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child:TextField(controller:_period,decoration:const InputDecoration(labelText:'Term / result period'))),
            const SizedBox(width:8),Expanded(child:TextField(controller:_year,decoration:const InputDecoration(labelText:'Academic year'))),
          ]),
          const SizedBox(height:8),
          Row(children:[
            Expanded(child:TextField(controller:_maxCa,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Maximum CA'))),
            const SizedBox(width:8),Expanded(child:TextField(controller:_maxExam,keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:const InputDecoration(labelText:'Maximum exam'))),
          ]),
          const SizedBox(height:9),
          SizedBox(width:double.infinity,child:FilledButton.icon(
            onPressed:_loadingRoster?null:_loadRoster,icon:const Icon(Icons.people_alt_outlined),
            label:Text(_loadingRoster?'Loading class register':'Load class register'),
            style:FilledButton.styleFrom(backgroundColor:const Color(0xFF4A3022)))),
          if(_periodStatus=='published')const Padding(padding:EdgeInsets.only(top:7),
            child:Text('This period is published. Saved corrections will update released results.',style:TextStyle(color:Colors.green,fontSize:12))),
        ])),
        const Divider(height:1),
        Expanded(child:_loadingRoster?const Center(child:CircularProgressIndicator())
          :_students.isEmpty?const Center(child:Text('Load a class register to enter scores.'))
          :ListView(padding:const EdgeInsets.all(14),children:[
            Text('${_students.length} learners • Enter each learner’s CA and exam marks',style:const TextStyle(fontWeight:FontWeight.w700)),
            const SizedBox(height:8),
            ..._students.map((student){
              final id=student['id'].toString();
              final ca=_value(_ca[id]!)??0;
              final exam=_value(_exam[id]!)??0;
              final maxCa=double.tryParse(_maxCa.text.trim())??40;
              final maxExam=double.tryParse(_maxExam.text.trim())??60;
              return Card(margin:const EdgeInsets.only(bottom:9),child:Padding(padding:const EdgeInsets.all(12),
                child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[
                  Text((student['profiles']?['full_name']??'Learner').toString(),style:const TextStyle(fontWeight:FontWeight.w800)),
                  const SizedBox(height:8),
                  Row(children:[
                    Expanded(child:TextField(controller:_ca[id],keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:'CA / $maxCa',isDense:true))),
                    const SizedBox(width:8),
                    Expanded(child:TextField(controller:_exam[id],keyboardType:const TextInputType.numberWithOptions(decimal:true),decoration:InputDecoration(labelText:'Exam / $maxExam',isDense:true))),
                  ]),
                  const SizedBox(height:8),
                  TextField(controller:_teacherComments[id],maxLines:2,
                    decoration:const InputDecoration(labelText:'Class teacher’s remark',isDense:true)),
                  const SizedBox(height:7),
                  TextField(controller:_headComments[id],maxLines:2,
                    decoration:const InputDecoration(labelText:'Centre coordinator’s remark',isDense:true)),
                  const SizedBox(height:7),
                  Row(children:[
                    Expanded(child:Text('Total: ${(ca+exam).toStringAsFixed(1)} / ${(maxCa+maxExam).toStringAsFixed(1)}',style:const TextStyle(fontWeight:FontWeight.w700))),
                    Text('Grade ${_grade(ca+exam,maxCa+maxExam)}',style:const TextStyle(fontWeight:FontWeight.w800,color:Color(0xFF4A3022))),
                    IconButton(tooltip:'Generate result sheet',onPressed:_saving?null:()=>_generate(student),icon:const Icon(Icons.picture_as_pdf_outlined)),
                  ]),
                ])));
            }),
            const SizedBox(height:8),
            FilledButton.icon(onPressed:_saving?null:()=>_save(),icon:const Icon(Icons.save_outlined),
              label:Text(_saving?'Saving...':'Save scores'),style:FilledButton.styleFrom(backgroundColor:const Color(0xFF4A3022))),
            const SizedBox(height:8),
            OutlinedButton.icon(onPressed:_saving?null:()=>_save(release:true),
              icon:const Icon(Icons.publish_outlined),label:const Text('Save and release results to students')),
          ])),
      ]);
    }),
  );
}
