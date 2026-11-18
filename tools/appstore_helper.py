#!/usr/bin/env python3
"""Fill App Store Connect version page via Google Chrome tab AppleScript."""
import json, subprocess, sys

PROMOTIONAL_TEXT = "مصحف رقمي متكامل، مع تلاوة متزامنة وتسميع ذكي يعمل على جهازك ومزامنة عبر iCloud."

DESCRIPTION = """«تبيان» مصحف رقمي متكامل، صُمم ليكون رفيقك اليومي في تلاوة كتاب الله وتدبره وحفظه.

يجمع التطبيق بين جمال الخط القرآني الأصيل وأحدث التقنيات التفاعلية، مع الحفاظ على هدوء التجربة وخلوها من أي مشتتات.

أهم مزايا تطبيق تبيان:

١. تلاوة متزامنة كلمةً كلمة:
استمع إلى تلاوة نخبة من كبار القرّاء في العالم الإسلامي مع إضاءة الكلمة المقروءة آنيًا لمساعدتك على ضبط التلاوة وتصحيح النطق ومتابعة الحفظ.

٢. مصحح التسميع الذكي:
نظام ذكي متطور يستمع لقراءتك وتسميعك للآيات، ويحدد بدقة مواضع الخطأ أو النسيان والتوقفات، كل ذلك يعمل محليًا على جهازك دون الحاجة للاتصال بالإنترنت حفاظًا على خصوصيتك وسرعة استجابتك.

٣. مصاحف متعددة وروايات متواترة:
اختر بين مصحف المدينة المنورة (طبعة 1441هـ وطبعة 1405هـ) ومصحف الشمرلي، مع دعم كامل للروايات القرآنية المتواترة (حفص عن عاصم، ورش عن نافع، قالون عن نافع، والدوري عن أبي عمرو).

٤. التفسير الميسر ومعاني الكلمات:
تصفح التفسير الميسر تحت كل آية بلمسة واحدة، واطّلع على معاني المفردات الغريبة، وأسباب النزول، وإعراب الآيات، مع إمكانية البحث الفوري في كلمات القرآن وتفسيره.

٥. رحلة حفظ تفاعلية:
نظام شامل لإدارة حفظك وتثبيته؛ خريطة مصورة للأجزاء والصفحات المتقنة والتي تحتاج إلى مراجعة، مع وضع مبتكر لإخفاء الكلمات لاختبار قوة استحضار الآيات.

٦. الختمات الفردية والجماعية:
أنشئ خطط ختم مرنة ومخصصة تناسب وقتك، أو شارك أفراد عائلتك وأصدقاءك في ختمات جماعية مع توزيع الأجزاء وتتبع الإنجاز خطوة بخطوة.

٧. جماليات التصميم والوضع الليلي:
ثلاثة أنماط إسلامية بديعة للواجهة (النمط الهندسي، نمط المخطوطة الأثرية، والنمط الليلي الذهبي)، بالإضافة إلى وضع خاص لكبار السن يتيح خطوطًا أكبر وواجهة مبسطة ومريحة للعين.

٨. مسبحة إلكترونية ذكية:
مسبحة رقمية ثلاثية الأبعاد تفاعلية، تحتوي على الأذكار المأثورة مع اهتزازات واقعية تشبه حبات المسبحة الحقيقية، مع تزامن فوري مع ساعات اليد الذكية (Apple Watch).

٩. مزامنة سحابية آمنة:
تزامن كامل لعلاماتك المرجعية، وختماتك، وسجل تلاوتك بين جميع أجهزتك (الهاتف، التابلت، الحاسوب، والساعة) عبر iCloud وGoogle Drive.

١٠. خاص تمامًا:
تطبيق تبيان لا يجمع بيانات شخصية، ويعمل محليًا على جهازك قدر الإمكان."""

KEYWORDS = "قرآن,مصحف,تلاوة,تفسير,تسميع,حفظ,المدينة,الشمرلي,أذكار,مسبحة,ختمة"
SUPPORT_URL = "https://altibyan.app/"
MARKETING_URL = "https://altibyan.app/beta"
COPYRIGHT = "2026 Tibyan"
REVIEW_NOTES = "التطبيق لا يتطلب أي حساب أو تسجيل دخول، ويعمل بالكامل دون اتصال بالإنترنت. لتجربة التسميع الذكي، يُرجى منح إذن الميكروفون عند طلب التطبيق."

def run_js(js_code):
    script = f'''
    tell application "Google Chrome"
        repeat with w in windows
            repeat with t in tabs of w
                if URL of t starts with "https://appstoreconnect.apple.com/apps/6818990351/distribution/ios/version/inflight" then
                    return execute t javascript "{js_code}"
                end if
            end repeat
        end repeat
    end tell
    '''
    res = subprocess.run(['osascript', '-e', script], capture_output=True, text=True)
    return res.stdout.strip(), res.stderr.strip()

def main():
    payload = {
        'promotionalText': PROMOTIONAL_TEXT,
        'description': DESCRIPTION,
        'keywords': KEYWORDS,
        'supportUrl': SUPPORT_URL,
        'marketingUrl': MARKETING_URL,
        'copyright': COPYRIGHT,
        'notes': REVIEW_NOTES,
    }
    
    js = f"""
    (() => {{
        const data = {json.dumps(payload)};
        const results = {{}};

        function setVal(id, val) {{
            const el = document.getElementById(id);
            if (!el) return 'not found';
            el.focus();
            
            // Native prototype setter for React/Angular/Vue inputs
            const proto = el.tagName.toLowerCase() === 'textarea' 
                ? window.HTMLTextAreaElement.prototype 
                : window.HTMLInputElement.prototype;
            const nativeSetter = Object.getOwnPropertyDescriptor(proto, 'value')?.set;
            if (nativeSetter) {{
                nativeSetter.call(el, val);
            }} else {{
                el.value = val;
            }}
            el.dispatchEvent(new Event('input', {{ bubbles: true, composed: true }}));
            el.dispatchEvent(new Event('change', {{ bubbles: true, composed: true }}));
            el.dispatchEvent(new Event('blur', {{ bubbles: true, composed: true }}));
            return 'set (' + el.value.length + ' chars)';
        }}

        for (const [key, val] of Object.entries(data)) {{
            results[key] = setVal(key, val);
        }}

        // Check demoAccountRequired checkbox
        const chk = document.getElementById('appStoreReviewDetails_demoAccountRequired');
        if (chk && chk.checked) {{
            chk.click();
            results['demoAccountRequired'] = 'unchecked';
        }} else if (chk) {{
            results['demoAccountRequired'] = 'already unchecked';
        }}

        return JSON.stringify(results);
    }})()
    """
    
    # Escape quotes and backslashes for AppleScript
    js_escaped = js.replace('\\', '\\\\').replace('"', '\\"')
    out, err = run_js(js_escaped)
    print("OUTPUT:", out)
    if err:
        print("ERROR:", err)

if __name__ == '__main__':
    main()
