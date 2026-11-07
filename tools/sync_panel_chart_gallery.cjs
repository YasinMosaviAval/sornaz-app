// Rebuild native demonstration data from the website; never from live accounts.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const crypto = require('node:crypto');
const webRoot = process.argv[2];
if (!webRoot) throw Error('Usage: node tools/sync_panel_chart_gallery.cjs <web-root>');
const source = fs.readFileSync(path.join(webRoot, 'assets/Analytics/js/chart-gallery.js'), 'utf8').replace(/\r\n/g, '\n');
const marker = '  function selectedTypes() {';
if (!source.includes(marker)) throw Error('Website gallery contract changed');
const sandbox = { window: {} };
vm.runInNewContext(source.replace(marker, '  window.nativeCatalog = {types, familyNames, option};\n' + marker), sandbox, { timeout: 1000 });
const catalog = sandbox.window.nativeCatalog;
const english = {
  line: ['Line', 'Time trends and comparison of multiple series'],
  bar: ['Bar and column', 'Category comparisons and rankings'],
  area: ['Area', 'Volume and cumulative trends'],
  pie: ['Pie and doughnut', 'Parts of a whole'],
  scatter: ['Scatter and bubble', 'Correlation and point distribution'],
  radar: ['Radar', 'Comparison across multiple indicators'],
  gauge: ['Gauge', 'Progress and key performance indicators'],
  funnel: ['Funnel', 'Conversion and attrition stages'],
  heatmap: ['Heatmap', 'Intensity across two dimensions'],
  candlestick: ['Candlestick', 'Financial samples and price ranges'],
  boxplot: ['Box plot', 'Median, quartiles and spread'],
  tree: ['Tree', 'Hierarchical structure'],
  treemap: ['Treemap', 'Hierarchical shares of space'],
  sunburst: ['Sunburst', 'Radial hierarchy'],
  graph: ['Network', 'Nodes and connections'],
  sankey: ['Sankey', 'Flows between stages'],
  pictorialBar: ['Pictorial bar', 'Values shown with repeating symbols'],
  parallel: ['Parallel coordinates', 'Multivariate record comparison'],
  themeRiver: ['Theme river', 'Changing topic shares over time'],
};
const labels = {
  'شنبه':'Saturday','یکشنبه':'Sunday','دوشنبه':'Monday','سه‌شنبه':'Tuesday','چهارشنبه':'Wednesday','پنجشنبه':'Thursday','جمعه':'Friday',
  'ثبت‌نام':'Enrollment','فروش':'Sales','پیانو':'Piano','گیتار':'Guitar','ویولن':'Violin','آواز':'Voice','دف':'Daf','سایر':'Other',
  'حضوری':'In person','آنلاین':'Online','شعبه مرکزی':'Central branch','شعبه غرب':'West branch','جلسه':'Session','امتیاز':'Score',
  'تکنیک':'Technique','ریتم':'Rhythm','تئوری':'Theory','خلاقیت':'Creativity','تمرین':'Practice','هنرجو الف':'Student A','هنرجو ب':'Student B',
  'بازدید':'Visits','خرید':'Purchases','تمدید':'Renewals','فروردین':'Farvardin','اردیبهشت':'Ordibehesht','خرداد':'Khordad','تیر':'Tir','مرداد':'Mordad',
  'کلاس الف':'Class A','کلاس ب':'Class B','کلاس ج':'Class C','آموزشگاه':'Academy','موسیقی کلاسیک':'Classical music','موسیقی ایرانی':'Iranian music',
  'تار':'Tar','سنتور':'Santur','مرکز':'Center','اعضا':'Members','عضویت':'Membership','ثبت‌نام دوره':'Course enrollment','ریزش':'Attrition',
  'حضور':'Attendance','اجرا':'Performance',
  'کل':'Total','پیشرفت':'Progress','نرخ حضور':'Attendance rate','مدیر':'Manager',
  'شعبه ۱':'Branch 1','شعبه ۲':'Branch 2','مدرس ۱':'Teacher 1','مدرس ۲':'Teacher 2','هنرجویان':'Students',
};
const familyEnglish = {comparison:'Comparison and trends',part:'Parts and composition',relation:'Relationships and hierarchy',distribution:'Distribution and statistics',special:'Specialized charts'};
const data = {
  version: 1,
  sourceSha256: crypto.createHash('sha256').update(source).digest('hex'),
  families: Object.entries(catalog.familyNames).map(([id, fa]) => ({id, fa, en:familyEnglish[id]})),
  labels,
  types: catalog.types.map(item => ({...item, en:english[item.id]?.[0], descriptionEn:english[item.id]?.[1],
    basic:catalog.option(item.id,false), advanced:catalog.option(item.id,true)})),
};
if (data.types.length !== 19 || data.types.some(x => !x.en || !x.descriptionEn)) throw Error('Update native gallery support for new website chart types');
const json = JSON.stringify(data, (key, value) => {
  if (typeof value !== 'function') return value;
  if (key !== 'symbolSize' || !String(value).includes('v[2] / 3')) throw Error('Unsupported website callback: ' + key);
  return {bubbleSize:true};
}, 2) + '\n';
const target = path.resolve(__dirname,'../assets/panel/chart-gallery.json');
fs.mkdirSync(path.dirname(target),{recursive:true});
fs.writeFileSync(target,json);
console.log('Synchronized 19 native gallery types and both variants from the website.');
