import "dart:html";import "dart:async";import "dart:js";const XB='mangledGlobalNames';const YB='mangledNames';const ZB='metadata';const aB='getIsolateTag';class BB{static const String bB="Chrome";static const String cB="Firefox";static const String dB="Internet Explorer";static const String eB="Opera";static const String fB="Safari";final String TB;final String minimumVersion;const BB(this.TB,[this.minimumVersion]);}class CB{const CB();}class DB{final String name;const DB(this.name);}class EB{const EB();}class FB{const FB();}class u{void UB(){gB();hB();iB();jB();kB();lB();mB();nB();}void gB(){Element j=querySelector('.close-jumbotron-button');Element k=querySelector('.open-jumbotron-button');if(j==null||k==null){return;}Element g=querySelector('.jumbotron');Element h=querySelector('.jumbotron-folded');j.onClick.listen((i){g.style.display='none';h.style.display='block';AB('closeJumbotron','1',expires:180);i.stopPropagation();});k.onClick.listen((i){g.style.display='block';h.style.display='none';AB('closeJumbotron','0',expires:180);i.stopPropagation();});if(IB('closeJumbotron')=='1'){g.style.display='none';h.style.display='block';}}void hB(){Element i=querySelector('.navbar-toggle-button');Element g=querySelector('.navbar-collapsible-block');bool h=false;var j=(l){if(h){g.classes..add('in')..remove('collapse')..remove('collapsing');}else{g.classes..add('collapse')..remove('collapsing')..remove('in');g.style.height='0';}};g.onTransitionEnd.listen(j);i.onClick.listen((m){h=!h;g.classes..add('collapsing')..remove('collapse')..remove('in');if(h){int k=g.scrollHeight+1;g.style.height="${k}px";}else{g.style.height="0";}});}void iB(){List<Node> k=document.getElementsByTagName('span');DateTime l=new DateTime.now();Duration m=l.timeZoneOffset;List<String> n=const['Понедельник','Вторник','Среда','Четверг','Пятница','Суббота','Воскресенье'];List<String> o=const['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];k.forEach((Element h){String i=h.dataset['postDate'];if(i==null){return;}DateTime j=DateTime.parse(i);if(j==null){return;}DateTime g=j.add(m);h.text="${n[g.weekday-1]}, ${g.day} ${o[g.month-1]} ${g.year}" ", ${g.hour<10?'0':''}${g.hour}:${g.minute<10?'0':''}${g.minute}";});}void jB(){ElementList h=querySelectorAll('span.post-comments');if(h.length==0){return;}new Timer.periodic(new Duration(microseconds:100),(l){if(h[0].text.startsWith('Считаем')){return;}l.cancel();h.forEach((Element m){Element i=m.querySelector('a');if(i==null){return;}i.text=i.text.replaceAllMapped(new RegExp('^(\\d+) комментариев\$'),(Match k){int g=int.parse(k[1]);if((g%100/10).round()!=1){int j=g%10;if(j==1){return '${g} комментарий';}else if(j>=2&&j<=4){return '${g} комментария';}}return k[0];});});});}void kB(){if(oB()){pB();}}bool oB(){final NodeValidatorBuilder q=new NodeValidatorBuilder.common()..allowElement('span',attributes:['data-linenum']);ElementList n=querySelectorAll('pre > code.sourceCode');if(n.length>0){JsObject s=context['hljs'];n.forEach((HtmlElement j){s.callMethod('highlightBlock',[j]);List<String> h=j.innerHtml.split('\n');RegExp t=new RegExp(r'<span[\s\S]*?>');RegExp VB=new RegExp(r'</span>');List<String> k=[] ;for(int g=0;g<h.length; ++g){String i='<span class="line" data-linenum="${g+1}">';if(h[g]==''){i+= '&nbsp;';}else{String l=k.join('')+h[g];i+= l;Iterable<Match> o=t.allMatches(l);Iterable<Match> WB=VB.allMatches(l);k=[] ;for(int m=WB.length;m<o.length; ++m){k.add(o.elementAt(m).group(0));i+= '</span>';}}i+= '</span>';h[g]=i;}j.setInnerHtml(h.join('\n'),validator:q);j.classes.add('highlighted');});return true;}else{return false;}}void pB(){Element k=new DivElement()..classes.add('tooltip-inner');Element g=new DivElement()..append(new DivElement()..classes.add('tooltip-arrow'))..append(k)..classes.addAll(['tooltip','left','fade']);g.classes.add(CssStyleDeclaration.supportsTransitions?'out':'in');g.style.display='none';document.body.append(g);g.onTransitionEnd.listen((TransitionEvent i){if(g.classes.contains('out')){g.style.display='none';}});void m(){if(!CssStyleDeclaration.supportsTransitions){g.style.display='none';}else{g.classes..remove('in')..add('out');}}void n(o){g.style..visibility='hidden'..display='block';g.style..left="${o.offsetLeft-g.clientWidth}px"..top="${o.offsetTop-2}px"..visibility="visible";if(CssStyleDeclaration.supportsTransitions){g.classes..remove('out')..add('in');}}Element h;bool j=false;var l=querySelectorAll('span.line');l.onClick.listen((MouseEvent i){if(h==i.currentTarget){if(!j){j=true;return;}m();h=null;j=false;return;}j=true;h=i.currentTarget;k.text='#'+h.getAttribute('data-linenum');n(h);});l.onMouseMove.listen((MouseEvent i){if(j||h==i.currentTarget){return;}h=i.currentTarget;k.text='#'+h.getAttribute('data-linenum');n(h);});l.onMouseOut.listen((MouseEvent i){if(j||h!=i.currentTarget){return;}m();h=null;});}void lB(){var j=querySelectorAll('.note-link');if(j.length==0){return;}Element k=new HeadingElement.h3()..classes.add('popover-title');DivElement l=new DivElement()..classes.add('popover-content');Element g=new DivElement()..append(new DivElement()..classes.add('arrow'))..append(k)..append(l)..classes.addAll(['popover','top','fade']);g.classes.add(CssStyleDeclaration.supportsTransitions?'out':'in');g.style.display='none';document.body.append(g);g.onTransitionEnd.listen((TransitionEvent m){if(g.classes.contains('out')){g.style.display='none';}});var i;final NodeValidatorBuilder o=new NodeValidatorBuilder.common()..allowNavigation(new GB());j.onClick.listen((MouseEvent m){var h=m.currentTarget;if(i==h){if(!CssStyleDeclaration.supportsTransitions){g.style.display='none';}else{g.classes..remove('in')..add('out');}i=null;return;}k.text="Примечание ${h.text}";var n=querySelector('.footnotes li[data-for=${h.id}]');if(n==null){return;}l.setInnerHtml(n.innerHtml,validator:o);i=h;g.style..visibility='hidden'..display='block';g.style..left="${h.offsetLeft+(h.clientWidth-g.clientWidth)/2+2}px"..top="${h.offsetTop-g.clientHeight}px"..visibility="visible";if(CssStyleDeclaration.supportsTransitions){g.classes..remove('out')..add('in');}});}void mB(){Element g=querySelector('.pager .previous');Element h=querySelector('.pager .next');bool k=window.navigator.platform.indexOf('Mac')!=-1;if(g!=null){g.attributes['title']+=" (${k?'⌥←':'Ctrl + ←'})";}if(h!=null){h.attributes['title']+=" (${k?'⌥→':'Ctrl + →'})";}if(g!=null||h!=null){document.onKeyDown.listen((KeyboardEvent i){if(i.altKey||i.ctrlKey){Element j;if(i.keyCode==KeyCode.LEFT){j=g;}else if(i.keyCode==KeyCode.RIGHT){j=h;}if(j!=null){window.location.replace(j.querySelector('a').getAttribute('href'));}}});}}void nB(){if(querySelectorAll('span.math').length>0){Element g=new ScriptElement()..type="text/javascript"..async=true..src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML";document.body.append(g);}}}class GB implements UriPolicy{bool allowsUri(String g){return true;}}void main(){u g=new u();g.UB();}String v(g)=>Uri.decodeComponent(g.replaceAll(r"\+",' '));String HB(DateTime l){var m=['Mon','Tue','Wed','Thi','Fri','Sat','Sun'];var n=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];var h=(int i,int o){var j=i.toString();var k=o-j.length;return (k>0)?'${new List.filled(k,'0').join('')}${i}':j;};var g=l.toUtc();var q=h(g.hour,2);var s=h(g.minute,2);var t=h(g.second,2);return '${m[g.weekday-1]}, ${g.day} ${n[g.month-1]} ${g.year} '+'${q}:${s}:${t} ${g.timeZoneName}';}String IB(String j){var m=new Map();var i=document.cookie!=null?document.cookie.split('; '):[] ;for(var g=0,k=i.length;g<k;g++ ){var h=i[g].split('=');var l=v(h[0]);if(j==l){return h[1]!=null?v(h[1]):null;}}return null;}void AB(String g,String h,{expires,path,domain,secure}){if(expires is num){expires=new DateTime.fromMillisecondsSinceEpoch(new DateTime.now().millisecondsSinceEpoch+expires*24*60*60*1000);}var i=([Uri.encodeComponent(g),'=',Uri.encodeComponent(h),expires!=null?'; expires='+HB(expires):'',path!=null?'; path='+path:'',domain!=null?'; domain='+domain:'',secure!=null&&secure==true?'; secure':''].join(''));document.cookie=i;}