const functions = require('firebase-functions');

const BACKEND_BASE_URL = 'https://api.romrom.suhsaechan.kr';
const HOSTING_URL = 'https://romrom-c4008.web.app';
const ANDROID_STORE_URL = 'https://play.google.com/store/apps/details?id=com.alom.romrom&hl=ko';
const IOS_STORE_URL = 'https://apps.apple.com/kr/app/%EB%A1%AC%EB%A1%AC-romrom-%ED%98%81%EC%8B%A0%EC%A0%81%EC%9D%B8-%EB%AC%BC%EB%AC%BC%EA%B5%90%ED%99%98/id6748823976';

// 백엔드 API 실패 시 사용하는 기본값
const DEFAULT_TITLE = '롬롬 - 물물교환 앱';
const DEFAULT_DESCRIPTION = '내 물건과 네 물건을 교환해보세요! 롬롬에서 물물교환 하세요.';
const DEFAULT_OG_IMAGE = `${HOSTING_URL}/og-default.png`;

/**
 * 아이템 공개 정보 조회
 * 백엔드 API: GET /api/item/public?itemId={itemId}
 */
async function fetchItemPublicInfo(itemId) {
  const res = await fetch(`${BACKEND_BASE_URL}/api/item/public/get?itemId=${encodeURIComponent(itemId)}`, {
    method: 'GET',
  });

  if (!res.ok) return null;

  const data = await res.json();
  const item = data?.item;
  if (!item) return null;

  return {
    itemName: item.itemName ?? null,
    itemDescription: item.itemDescription ?? null,
    primaryImageUrl: item.itemImages?.[0]?.imageUrl ?? null,
    price: item.price ?? null,
  };
}

/**
 * OG 태그 포함 HTML 생성
 */
function buildHtml({ itemId, itemName, itemDescription, primaryImageUrl, price }) {
  const title = itemName ? `${itemName} | 롬롬` : DEFAULT_TITLE;
  const description = buildDescription(itemDescription, price);
  const image = primaryImageUrl || DEFAULT_OG_IMAGE;
  const url = `${HOSTING_URL}/item?itemId=${itemId}`;
  const deepLink = `romrom://item/detail?itemId=${encodeURIComponent(itemId)}`;

  return `<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${escapeHtml(title)}</title>

  <!-- Open Graph -->
  <meta property="og:type" content="website" />
  <meta property="og:site_name" content="롬롬" />
  <meta property="og:title" content="${escapeHtml(title)}" />
  <meta property="og:description" content="${escapeHtml(description)}" />
  <meta property="og:image" content="${escapeHtml(image)}" />
  <meta property="og:url" content="${escapeHtml(url)}" />

  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image" />
  <meta name="twitter:title" content="${escapeHtml(title)}" />
  <meta name="twitter:description" content="${escapeHtml(description)}" />
  <meta name="twitter:image" content="${escapeHtml(image)}" />

  <style>
    body {
      background: #1D1E27;
      color: #fff;
      font-family: sans-serif;
      display: flex;
      flex-direction: column;
      align-items: center;
      justify-content: center;
      min-height: 100vh;
      margin: 0;
      text-align: center;
    }
    a.btn {
      display: inline-block;
      margin: 12px;
      padding: 14px 28px;
      background: #FFD600;
      color: #1D1E27;
      border-radius: 8px;
      text-decoration: none;
      font-weight: bold;
    }
  </style>
  <script>
    (function () {
      var ua = navigator.userAgent.toLowerCase();
      var isAndroid = ua.indexOf('android') > -1;
      var isIOS = /iphone|ipad|ipod/.test(ua);
      var deepLink = '${deepLink}';
      var storeUrl = isAndroid ? '${ANDROID_STORE_URL}' : '${IOS_STORE_URL}';

      if (!isAndroid && !isIOS) return;

      var appOpened = false;

      // 앱이 열리면 페이지가 숨겨짐 → 스토어 이동 취소
      document.addEventListener('visibilitychange', function () {
        if (document.hidden) appOpened = true;
      });

      // 커스텀 스킴으로 앱 열기 시도
      window.location = deepLink;

      // 2초 후에도 앱이 안 열렸으면 스토어로 이동
      setTimeout(function () {
        if (!appOpened) window.location = storeUrl;
      }, 2000);
    })();
  </script>
</head>
<body>
  <p style="font-size:20px; font-weight:bold;">롬롬 앱으로 이동 중...</p>
  <p style="color:#aaa;">앱이 열리지 않으면 아래 버튼을 눌러 앱을 설치해 주세요.</p>
  <a class="btn" href="${ANDROID_STORE_URL}">Android 다운로드</a>
  <a class="btn" href="${IOS_STORE_URL}">iOS 다운로드</a>
</body>
</html>`;
}

/**
 * og:description 조합
 * - 백엔드 성공: "50,000원 · 거의 새것입니다."
 * - 백엔드 실패: 기본 문구
 */
function buildDescription(itemDescription, price) {
  if (!itemDescription && price == null) return DEFAULT_DESCRIPTION;
  const parts = [];
  if (price != null) parts.push(`${price.toLocaleString('ko-KR')}원`);
  if (itemDescription) parts.push(itemDescription);
  return parts.join(' · ');
}

function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;');
}

/**
 * /item?itemId={itemId} 요청 처리
 * - 크롤러: OG 태그 포함 HTML 반환
 * - 일반 유저: 앱 딥링크 + 스토어 리다이렉트
 */
exports.itemOgRenderer = functions.https.onRequest(async (req, res) => {
  const itemId = req.query.itemId;

  if (!itemId) {
    res.status(400).send('itemId가 필요합니다.');
    return;
  }

  let itemData = null;
  try {
    itemData = await fetchItemPublicInfo(itemId);
  } catch (e) {
    functions.logger.warn('아이템 정보 조회 실패 - 기본값으로 렌더링', { itemId, error: e.message });
  }

  const html = buildHtml({
    itemId,
    itemName: itemData?.itemName ?? null,
    itemDescription: itemData?.itemDescription ?? null,
    primaryImageUrl: itemData?.primaryImageUrl ?? null,
    price: itemData?.price ?? null,
  });

  // 백엔드 실패 시 캐시 안 함 (백엔드 복구 후 즉시 반영되도록)
  // 백엔드 성공 시 5분 캐시
  const cacheControl = itemData
    ? 'public, max-age=300, s-maxage=300'
    : 'no-store';
  res.set('Cache-Control', cacheControl);
  res.status(200).send(html);
});
