document.addEventListener("DOMContentLoaded", () => {
  initScrollAnimations();
  initDownloadButtons();
  initDarkMode();
});

function initScrollAnimations() {
    // 히어로 fade-up
    const fadeObserver = new IntersectionObserver(
        (entries, obs) => {
            entries.forEach((entry) => {
                if (entry.isIntersecting) {
                    entry.target.classList.add("in-view");
                    obs.unobserve(entry.target);
                }
            });
        },
        { root: null, rootMargin: "0px 0px -50px 0px", threshold: 0.1 },
    );
    document.querySelectorAll(".fade-up").forEach((el) => fadeObserver.observe(el));

    // 스냅 섹션 자체를 관찰 → 섹션이 30% 이상 보이면 내부 텍스트 전체 트리거
    const sectionObserver = new IntersectionObserver(
        (entries, obs) => {
            entries.forEach((entry) => {
                if (entry.isIntersecting) {
                    entry.target
                        .querySelectorAll(".anim-number, .anim-heading-line, .anim-desc")
                        .forEach((el) => el.classList.add("in-view"));
                    obs.unobserve(entry.target);
                }
            });
        },
        { root: null, rootMargin: "0px", threshold: 0.3 },
    );
    document.querySelectorAll(".snap-section").forEach((el) => sectionObserver.observe(el));
}

function initDarkMode() {
  const html = document.documentElement;
  const toggle = document.getElementById("theme-toggle");
  const icon = document.getElementById("theme-icon");

  // 초기 로드 후 no-dark-transition 제거 (FOUC 방지 완료)
  requestAnimationFrame(() => {
    requestAnimationFrame(() => {
      html.classList.remove("no-dark-transition");
    });
  });

  // 현재 상태에 맞는 아이콘 동기화
  const syncIcon = () => {
    icon.className = html.classList.contains("dark")
      ? "fa-solid fa-sun"
      : "fa-solid fa-moon";
  };
  syncIcon();

  // 토글 클릭
  toggle.addEventListener("click", () => {
    html.classList.toggle("dark");
    const isDark = html.classList.contains("dark");
    localStorage.setItem("romrom-theme", isDark ? "dark" : "light");
    syncIcon();
  });

  // 시스템 다크모드 변경 감지 (localStorage 설정 없는 경우만)
  window
    .matchMedia("(prefers-color-scheme: dark)")
    .addEventListener("change", (e) => {
      if (!localStorage.getItem("romrom-theme")) {
        html.classList.toggle("dark", e.matches);
        syncIcon();
      }
    });
}

function initDownloadButtons() {
  const modal = document.getElementById("download-modal");
  const modalCard = document.getElementById("download-modal-card");
  const closeBtn = document.getElementById("download-modal-close");
  const qrItems = document.querySelectorAll(".download-qr");
  const grid = document.getElementById("download-modal-grid");
  const r = window._romrom || {};

  const openModal = (store) => {
    const showSingle = Boolean(store);
    modal.classList.remove("hidden");
    modal.setAttribute("aria-hidden", "false");
    document.body.style.overflow = "hidden";

    modalCard.classList.toggle("max-w-[520px]", showSingle);
    modalCard.classList.toggle("max-w-[640px]", !showSingle);
    grid.classList.toggle("sm:grid-cols-1", showSingle);
    grid.classList.toggle("sm:grid-cols-2", !showSingle);

    qrItems.forEach((item) => {
      item.classList.toggle(
        "hidden",
        Boolean(store) && item.dataset.store !== store,
      );
    });
  };

  const closeModal = () => {
    modal.classList.add("hidden");
    modal.setAttribute("aria-hidden", "true");
    document.body.style.overflow = "";
  };

  document.querySelectorAll(".js-download-trigger").forEach((button) => {
    button.addEventListener("click", () => {
      const store = button.dataset.store;

      if (r.isMobile) {
        // 모바일: OS에 맞는 스토어로 바로 이동
        const goToAppStore = store === "appstore" || r.isIOS;
        window.location.href = goToAppStore ? r.iosUrl : r.androidUrl;
        return;
      }

      // 데스크탑: QR 모달 표시
      openModal(store || null);
    });
  });

  closeBtn.addEventListener("click", closeModal);

  modal.addEventListener("click", (e) => {
    if (e.target === modal.firstElementChild) closeModal();
  });

  document.addEventListener("keydown", (e) => {
    if (e.key === "Escape" && modal.getAttribute("aria-hidden") === "false")
      closeModal();
  });
}
