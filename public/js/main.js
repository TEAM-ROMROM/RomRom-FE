document.addEventListener('DOMContentLoaded', () => {
    initScrollAnimations();
    initDownloadButtons();
});

function initScrollAnimations() {
    const observer = new IntersectionObserver((entries, obs) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('in-view');
                obs.unobserve(entry.target);
            }
        });
    }, { root: null, rootMargin: '0px 0px -50px 0px', threshold: 0.1 });

    document.querySelectorAll('.fade-up').forEach(el => observer.observe(el));
}

function initDownloadButtons() {
    const modal     = document.getElementById('download-modal');
    const modalCard = document.getElementById('download-modal-card');
    const closeBtn  = document.getElementById('download-modal-close');
    const qrItems   = document.querySelectorAll('.download-qr');
    const grid      = document.getElementById('download-modal-grid');
    const r         = window._romrom || {};

    const openModal = (store) => {
        const showSingle = Boolean(store);
        modal.classList.remove('hidden');
        modal.setAttribute('aria-hidden', 'false');
        document.body.style.overflow = 'hidden';

        modalCard.classList.toggle('max-w-[520px]', showSingle);
        modalCard.classList.toggle('max-w-[640px]', !showSingle);
        grid.classList.toggle('sm:grid-cols-1', showSingle);
        grid.classList.toggle('sm:grid-cols-2', !showSingle);

        qrItems.forEach(item => {
            item.classList.toggle('hidden', Boolean(store) && item.dataset.store !== store);
        });
    };

    const closeModal = () => {
        modal.classList.add('hidden');
        modal.setAttribute('aria-hidden', 'true');
        document.body.style.overflow = '';
    };

    document.querySelectorAll('.js-download-trigger').forEach(button => {
        button.addEventListener('click', () => {
            const store = button.dataset.store;

            if (r.isMobile) {
                // 모바일: OS에 맞는 스토어로 바로 이동
                const goToAppStore  = store === 'appstore' || r.isIOS;
                window.location.href = goToAppStore ? r.iosUrl : r.androidUrl;
                return;
            }

            // 데스크탑: QR 모달 표시
            openModal(store || null);
        });
    });

    closeBtn.addEventListener('click', closeModal);

    modal.addEventListener('click', (e) => {
        if (e.target === modal.firstElementChild) closeModal();
    });

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape' && modal.getAttribute('aria-hidden') === 'false') closeModal();
    });
}
