import "dart:html" as m;import "dart:js" as HB;import "dart:async" as TB;class IB{static const String JB="Chrome";static const String KB="Firefox";static const String LB="Internet Explorer";static const String MB="Opera";static const String NB="Safari";final String DB;final String minimumVersion;const IB(this.DB,[this.minimumVersion]);}class OB{const OB();}class PB{final String name;const PB(this.name);}class QB{const QB();}class RB{const RB();}class AB{void EB(){UB();VB();WB();XB();YB();ZB();aB();bB();}void UB(){m.Element j=m.querySelector('.close-jumbotron-button');m.Element k=m.querySelector('.open-jumbotron-button');if(j==null||k==null){return;}m.Element g=m.querySelector('.jumbotron');m.Element h=m.querySelector('.jumbotron-folded');j.onClick.listen((i){g.style.display='none';h.style.display='block';v('closeJumbotron','1',expires:180);i.stopPropagation();});k.onClick.listen((i){g.style.display='block';h.style.display='none';v('closeJumbotron','1',expires:180);i.stopPropagation();});if(CB('closeJumbotron')=='1'){g.style.display='none';h.style.display='block';}}void VB(){m.Element i=m.querySelector('.navbar-toggle-button');m.Element g=m.querySelector('.navbar-collapsible-block');bool h=false;var j=(cB){if(h){g.classes..add('in')..remove('collapse')..remove('collapsing');}else{g.classes..add('collapse')..remove('collapsing')..remove('in');g.style.height='0';}};g.onTransitionEnd.listen(j);i.onClick.listen((l){h=!h;g.classes..add('collapsing')..remove('collapse')..remove('in');if(h){int k=g.scrollHeight+1;g.style.height="${k}px";}else{g.style.height="0";}});}void WB(){List<m.Node> k=m.document.getElementsByTagName('span');DateTime l=new DateTime.now();Duration n=l.timeZoneOffset;List<String> o=const['Понедельник','Вторник','Среда','Четверг','Пятница','Суббота','Воскресенье'];List<String> q=const['января','февраля','марта','апреля','мая','июня','июля','августа','сентября','октября','ноября','декабря'];k.forEach((m.Element h){String i=h.dataset['postDate'];if(i==null){return;}DateTime j=DateTime.parse(i);if(j==null){return;}DateTime g=j.add(n);h.text="${o[g.weekday-1]}, ${g.day} ${q[g.month-1]} ${g.year}" ", ${g.hour<10?'0':''}${g.hour}:${g.minute<10?'0':''}${g.minute}";});}void XB(){m.ElementList h=m.querySelectorAll('span.post-comments');if(h.length==0){return;}new TB.Timer.periodic(new Duration(microseconds:100),(l){if(h[0].text.startsWith('Считаем')){return;}l.cancel();h.forEach((m.Element n){m.Element i=n.querySelector('a');if(i==null){return;}i.text=i.text.replaceAllMapped(new RegExp('^(\\d+) комментариев\$'),(Match k){int g=int.parse(k[1]);if((g%100/10).round()!=1){int j=g%10;if(j==1){return '${g} комментарий';}else if(j>=2&&j<=4){return '${g} комментария';}}return k[0];});});});}void YB(){if(dB()){eB();}}bool dB(){final m.NodeValidatorBuilder fB=new m.NodeValidatorBuilder.common()..allowElement('span',attributes:['data-linenum']);m.ElementList o=m.querySelectorAll('pre > code.sourceCode');if(o.length>0){HB.JsObject s=HB.context['hljs'];o.forEach((m.HtmlElement j){s.callMethod('highlightBlock',[j]);List<String> h=j.innerHtml.split('\n');RegExp t=new RegExp(r'<span[\s\S]*?>');RegExp FB=new RegExp(r'</span>');List<String> k=[] ;for(int g=0;g<h.length; ++g){String i='<span class="line" data-linenum="${g+1}">';if(h[g]==''){i+= '&nbsp;';}else{String l=k.join('')+h[g];i+= l;Iterable<Match> q=t.allMatches(l);Iterable<Match> GB=FB.allMatches(l);k=[] ;for(int n=GB.length;n<q.length; ++n){k.add(q.elementAt(n).group(0));i+= '</span>';}}i+= '</span>';h[g]=i;}j.setInnerHtml(h.join('\n'),validator:fB);j.classes.add('highlighted');});return true;}else{return false;}}void eB(){m.Element k=new m.DivElement()..classes.add('tooltip-inner');m.Element g=new m.DivElement()..append(new m.DivElement()..classes.add('tooltip-arrow'))..append(k)..classes.addAll(['tooltip','left','fade']);g.classes.add(m.CssStyleDeclaration.supportsTransitions?'out':'in');g.style.display='none';m.document.body.append(g);g.onTransitionEnd.listen((m.TransitionEvent i){if(g.classes.contains('out')){g.style.display='none';}});void n(){if(!m.CssStyleDeclaration.supportsTransitions){g.style.display='none';}else{g.classes..remove('in')..add('out');}}void o(q){g.style..visibility='hidden'..display='block';g.style..left="${q.offsetLeft-g.clientWidth}px"..top="${q.offsetTop-2}px"..visibility="visible";if(m.CssStyleDeclaration.supportsTransitions){g.classes..remove('out')..add('in');}}m.Element h;bool j=false;var l=m.querySelectorAll('span.line');l.onClick.listen((m.MouseEvent i){if(h==i.currentTarget){if(!j){j=true;return;}n();h=null;j=false;return;}j=true;h=i.currentTarget;k.text='#'+h.getAttribute('data-linenum');o(h);});l.onMouseMove.listen((m.MouseEvent i){if(j||h==i.currentTarget){return;}h=i.currentTarget;k.text='#'+h.getAttribute('data-linenum');o(h);});l.onMouseOut.listen((m.MouseEvent i){if(j||h!=i.currentTarget){return;}n();h=null;});}void ZB(){var j=m.querySelectorAll('.note-link');if(j.length==0){return;}m.Element k=new m.HeadingElement.h3()..classes.add('popover-title');m.DivElement l=new m.DivElement()..classes.add('popover-content');m.Element g=new m.DivElement()..append(new m.DivElement()..classes.add('arrow'))..append(k)..append(l)..classes.addAll(['popover','top','fade']);g.classes.add(m.CssStyleDeclaration.supportsTransitions?'out':'in');g.style.display='none';m.document.body.append(g);g.onTransitionEnd.listen((m.TransitionEvent n){if(g.classes.contains('out')){g.style.display='none';}});var i;final m.NodeValidatorBuilder fB=new m.NodeValidatorBuilder.common()..allowNavigation(new SB());j.onClick.listen((m.MouseEvent n){var h=n.currentTarget;if(i==h){if(!m.CssStyleDeclaration.supportsTransitions){g.style.display='none';}else{g.classes..remove('in')..add('out');}i=null;return;}k.text="Примечание ${h.text}";var o=m.querySelector('.footnotes li[data-for=${h.id}]');if(o==null){return;}l.setInnerHtml(o.innerHtml,validator:fB);i=h;g.style..visibility='hidden'..display='block';g.style..left="${h.offsetLeft+(h.clientWidth-g.clientWidth)/2+2}px"..top="${h.offsetTop-g.clientHeight}px"..visibility="visible";if(m.CssStyleDeclaration.supportsTransitions){g.classes..remove('out')..add('in');}});}void aB(){m.Element g=m.querySelector('.pager .previous');m.Element h=m.querySelector('.pager .next');bool k=m.window.navigator.platform.indexOf('Mac')!=-1;if(g!=null){g.attributes['title']+=" (${k?'⌥←':'Ctrl + ←'})";}if(h!=null){h.attributes['title']+=" (${k?'⌥→':'Ctrl + →'})";}if(g!=null||h!=null){m.document.onKeyDown.listen((m.KeyboardEvent i){if(i.altKey||i.ctrlKey){m.Element j;if(i.keyCode==m.KeyCode.LEFT){j=g;}else if(i.keyCode==m.KeyCode.RIGHT){j=h;}if(j!=null){m.window.location.replace(j.querySelector('a').getAttribute('href'));}}});}}void bB(){if(m.querySelectorAll('span.math').length>0){m.Element g=new m.ScriptElement()..type="text/javascript"..async=true..src="http://cdn.mathjax.org/mathjax/latest/MathJax.js?config=TeX-AMS_HTML";m.document.body.append(g);}}}class SB implements m.UriPolicy{bool allowsUri(String g){return true;}}void main(){AB g=new AB();g.EB();}String u(g)=>Uri.decodeComponent(g.replaceAll(r"\+",' '));String BB(DateTime k){var l=['Mon','Tue','Wed','Thi','Fri','Sat','Sun'];var n=['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];var gB=(int h,int o){var i=h.toString();var j=o-i.length;return (j>0)?'${new List.filled(j,'0').join('')}${h}':i;};var g=k.toUtc();var q=gB(g.hour,2);var s=gB(g.minute,2);var t=gB(g.second,2);return '${l[g.weekday-1]}, ${g.day} ${n[g.month-1]} ${g.year} '+'${q}:${s}:${t} ${g.timeZoneName}';}String CB(String j){var n=new Map();var i=m.document.cookie!=null?m.document.cookie.split('; '):[] ;for(var g=0,k=i.length;g<k;g++ ){var h=i[g].split('=');var l=u(h[0]);if(j==l){return h[1]!=null?u(h[1]):null;}}return null;}void v(String g,String h,{expires,path,domain,secure}){if(expires is num){expires=new DateTime.fromMillisecondsSinceEpoch(new DateTime.now().millisecondsSinceEpoch+expires*24*60*60*1000);}var i=([Uri.encodeComponent(g),'=',Uri.encodeComponent(h),expires!=null?'; expires='+BB(expires):'',path!=null?'; path='+path:'',domain!=null?'; domain='+domain:'',secure!=null&&secure==true?'; secure':''].join(''));m.document.cookie=i;}
//# sourceMappingURL=script.dart.map
//@ sourceMappingURL=script.dart.map
