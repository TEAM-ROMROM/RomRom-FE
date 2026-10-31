/**
 * 딥링크 처리: 파라미터 보존 > 앱 열기 시도 > 실패 시 OS별 스토어 이동
 * 지원 경로는 lib/utils/deep_link_router.dart 와 동일 (romrom://item/detail?itemId=XXX)
 * 스토어 URL 원본: app-config.js (lib/models/app_urls.dart 와 값 동기화)
 */
(function () {
  // 앱 열기 시도 후 스토어로 넘어가기까지 대기 시간
  var APP_OPEN_WAIT_MILLISECONDS = 1500;
  // localStorage: 앱 설치 유도 시점까지 보존할 딥링크 파라미터 (Deferred)
  var PENDING_DEEP_LINK_STORAGE_KEY = "romrom-pending-deeplink";
  // itemId 허용 길이 (비정상 값이 앱 스킴에 실리지 않도록 제한)
  var MAX_ITEM_ID_LENGTH = 128;

  var userAgent = navigator.userAgent.toLowerCase();
  var isAndroid = userAgent.indexOf("android") > -1;
  var isIOS = /iphone|ipad|ipod/.test(userAgent);
  var isMobile = isAndroid || isIOS;

  var appConfig = window.APP_CONFIG || {};
  var androidUrl =
    appConfig.androidStoreUrl ||
    "https://play.google.com/store/apps/details?id=com.alom.romrom";
  var iosUrl =
    appConfig.iosStoreUrl || "https://apps.apple.com/kr/app/id6748823976";

  var rawItemId = new URLSearchParams(window.location.search).get("itemId");
  var itemId =
    rawItemId && rawItemId.length <= MAX_ITEM_ID_LENGTH ? rawItemId : null;

  window._romrom = {
    isMobile: isMobile,
    isIOS: isIOS,
    androidUrl: androidUrl,
    iosUrl: iosUrl,
  };

  if (!itemId) return;

  // 파라미터 보존 (사생활 보호 모드 등 저장소 차단 시 무시)
  try {
    localStorage.setItem(
      PENDING_DEEP_LINK_STORAGE_KEY,
      JSON.stringify({ itemId: itemId, savedAt: Date.now() }),
    );
  } catch (error) {}

  // 데스크탑: 랜딩 노출 + QR 다운로드 모달 사용
  if (!isMobile) return;

  var isAppOpened = false;
  var storeRedirectTimer = null;

  function markAppOpened() {
    isAppOpened = true;
    if (storeRedirectTimer) clearTimeout(storeRedirectTimer);
  }

  // 앱 전환 감지 (화면 숨김, 페이지 이탈)
  document.addEventListener("visibilitychange", function () {
    if (document.hidden) markAppOpened();
  });
  window.addEventListener("pagehide", markAppOpened);

  // 앱 스킴 열기 > 대기 후 미전환이면 스토어 이동
  window.location =
    "romrom://item/detail?itemId=" + encodeURIComponent(itemId);
  storeRedirectTimer = setTimeout(function () {
    if (!isAppOpened) window.location = isIOS ? iosUrl : androidUrl;
  }, APP_OPEN_WAIT_MILLISECONDS);
})();
