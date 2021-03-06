/*  
* @Author: yz.yujingzhou     
* @Date: 2020-09-01 21:23:05     
 * @Last Modified by: yz.yujingzhou
 * @Last Modified time: 2020-10-22 15:03:03
**/   

import 'package:flutter/material.dart';
import 'tools/common.dart';
import 'pages/basic/page.dart';
import 'pages/builder.dart';
import 'pages/model/page_config.dart';
import 'pages/basic/utils.dart';

export 'package:flutter/material.dart';
export 'package:yz_flutter_dynamic/pages/basic/page.dart';
export 'package:yz_flutter_dynamic/tools/common.dart';
export 'package:yz_flutter_dynamic/tools/action.dart';
export 'package:yz_flutter_dynamic/tools/variable.dart';
export 'package:yz_flutter_dynamic/tools/network.dart';
export 'package:yz_flutter_dynamic/widgets/basic/handler.dart';
export 'package:yz_flutter_dynamic/widgets/basic/widget.dart';
export 'package:yz_flutter_dynamic/widgets/basic/data.dart';
export 'package:yz_flutter_dynamic/widgets/basic/utils.dart';

class YZDynamic {
  YZDynamic._();

  static Widget buildPage(BuildContext context, Map config, {YZDynamicPagePreConfig preConfig}) {
    Widget widget;

    //You shoud register widgets first or it wouldn't create widget
    YZDynamicCommon.registerSysWidgets();
    //You shoud register sys public action first or it wouldn't be found
    YZDynamicCommon.registerSysPublicActionHandlers();

    widget = YZDynamicPageTemplateBuilder.build(context, config, preConfig: preConfig);

    return widget;
  }

  static Widget buildWidget(BuildContext context, Map config, {YZDynamicPagePreConfig preConfig}) {
    Widget widget;

    if (config['page'] == null) {
      Map json = {
        "page": {
            "rootWidget": config.cast<String, dynamic>()
        }
      }; 

      widget = YZDynamic.buildPage(context, json, preConfig: preConfig);
    }

    return widget;
  }  

  static handle(BuildContext context, Map dsl, {YZDynamicPagePreConfig preConfig}){

    assert(dsl != null, 'Error: Dsl can not be null!');
    if (dsl == null || dsl.isEmpty) {      
      return null;
    }

    Map config = dsl;

    Map _pageConfig = config['page'];
    YZDynamicPageTemplateConfig _pageConfigObj = YZDynamicPageTemplateConfig.fromJson(_pageConfig);
    String _presentMode = _pageConfigObj.presentMode;    

    YZDinamicPageMode _mode = YZDinamicPageUtils.pageMode(_presentMode);
    switch (_mode) {
      case YZDinamicPageMode.dialog:
        () async{
          await showDialog(
            context: context, 
            builder: (BuildContext context) {
              Widget child = YZDynamic.buildPage(context, config, preConfig: preConfig);
              return Dialog(child: child);
            }
          );
        }();
        break;
      default:
        Navigator.of(context).push(MaterialPageRoute(builder: (BuildContext contex){
          return YZDynamic.buildPage(context, config, preConfig: preConfig);
        }));
    }

  }  

}
