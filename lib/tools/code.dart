/* 
 * @Author: yz.yujingzhou 
 * @Date: 2020-10-25 17:13:52 
 * @Last Modified by: yz.yujingzhou
 * @Last Modified time: 2020-11-17 19:30:01
 */

import 'package:flutter/material.dart';
import 'action.dart';
import 'variable.dart';

part 'code/lexical_analyzer.dart';

const _YZDynamicCodeTag = 'code:';
///表示不会对代码块进行预解释anylizeParams，解释的过程交给具体的action内部去处理
const _YZDynamicCodeActionTag = 'lazyCode:';
///用户自定义的语法格式
///User define codd grammar
const _YZDynamicUserdefCodeActionTag = '@userCode:';
///语句简单化分隔符，避免分号嵌套
///exucution split symbol avoiding nested semicolon
const YZDynamicParamsValuePlit = ';'; 

class YZDynamicCodeUtil {
  YZDynamicCodeUtil._();

  static bool isCode(String code) {
    if (code != null && code.trim().startsWith(_YZDynamicCodeTag)) return true;
    return false;
  } 

  static bool isCodeAction(String code) {
    if (code != null && code.trim().startsWith(_YZDynamicCodeActionTag)) return true;
    return false;
  }   

  /// 分析code字符串格式并执行action。注意分号;不能嵌套，params里面用逗号替代
  /// Anylize code string and execute action. The semicolon should not be nesting instead of comma used inside params
  /// The code string format as : "code:action:{};action:{};"
  static dynamic execute<T>(String code, {State state, Map localVariables}) {

    int tagLen = _YZDynamicCodeTag.length;
    if (code == null) return null;
    String codeTrim = code.replaceAll(RegExp(r"[\f\n\r\t\v]"), '');
    if (codeTrim.length <= tagLen) return null;

    dynamic result;
    
    // 存储各项命令执行的变量或临时结果或action句柄
    // Store the results or variables or actions handler of every command
    // Similar function context
    Map _localVariables = localVariables ?? {};
    
    String codeBody;
    List<String> commandItems;
    code = code.trim();

    if (code.startsWith(_YZDynamicCodeTag)) {

      codeBody = code.substring(_YZDynamicCodeTag.length);
      commandItems = splitLexical(codeBody, YZDynamicParamsValuePlit);

    } else if (code.startsWith(_YZDynamicCodeActionTag)) {

      codeBody = code.substring(_YZDynamicCodeActionTag.length);
      commandItems = splitLexical(codeBody, YZDynamicParamsValuePlit);

    } else if (code.startsWith(_YZDynamicUserdefCodeActionTag)) {

    } else {

      codeBody = code;
      commandItems = splitLexical(codeBody, YZDynamicParamsValuePlit);

    }        

    // 返回最后一项action命令的值
    // Return the last action result
    for (int i = 0; i < commandItems?.length ?? 0; i++) {
      String command = commandItems[i];
      command = command.trim();
      if (YZDynamicActionTool.isAction(command) || YZDynamicActionTool.isKeyAction(command)) { //action

        YZDynamicActionConfig action = YZDynamicActionTool.anylizeAction(command, state:state, localVariables: _localVariables);     

        result = YZDynamicActionTool.triggerActions<T>(state, [action], localVariables: _localVariables);
        if (result != null && action.returnVariable != null) {
          _localVariables[action.returnVariable] = result;
        }

      } else if (YZDynamicVariableUtil.isVariable(command)) { //variable
        YZDynamicVariableUtil.assignmentVariable(
          command,
          state: state,
          localVariables: _localVariables
        );
      } else { //lexical
        dynamic commandResult = YZDynamicLexicalAnalysis.analyze(command);
        if (commandResult is YZDynamicActionConfig) {
          result = YZDynamicActionTool.triggerActions<T>(state, [commandResult], localVariables: _localVariables);        
        }
      }
    }

    return result;

  }

  ///Split by tag ";" without inside {} such as {xxx;xxx;}, or (int i=0; i<=...)
  static List<String> splitLexical(String str, String split) {

    List<String> lexicalStr = [];
    int braceCount = 0;
    int parenthesesCount = 0;
    int semicolonIndex = 0;
    for (var i = 0; i < str.length; i++) {
      String c = str.substring(i, i+1);
      if (c == '{') {
        braceCount++;
      } else if (c == '}'){
        braceCount--;
      }

      if (c == '(') {
        parenthesesCount++;
      } else if (c == ')'){
        parenthesesCount--;
      }      

      if (i == str.length - 1 && c != YZDynamicParamsValuePlit) {
        lexicalStr.add(str.substring(semicolonIndex, i + 1));
        break;
      }

      if (c == YZDynamicParamsValuePlit && (braceCount <= 0 && parenthesesCount <= 0)) {  
        lexicalStr.add(str.substring(semicolonIndex, i));
        semicolonIndex = i + 1;
      }
    }

    if (braceCount > 0) {
      print('Warming: There may be redundant "{" in the string!');
    }

    return lexicalStr;
  }

}
