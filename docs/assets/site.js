/* harness-edu 설치가이드 공용 스크립트
   1) 코드 블록 복사 버튼
   2) 사이드바 목차 현재 위치 표시 */

(function () {
  'use strict';

  // ── 1. 복사 버튼 ────────────────────────────────────────────
  document.querySelectorAll('[data-copy]').forEach(function (btn) {
    btn.addEventListener('click', function () {
      var card = btn.closest('.code-card') || btn.closest('.terminal');
      var pre = card && card.querySelector('pre');
      if (!pre) return;

      var text = pre.innerText.replace(/\u00a0/g, ' ');
      var done = function () {
        var original = btn.textContent;
        btn.textContent = '복사됨';
        btn.classList.add('done');
        setTimeout(function () {
          btn.textContent = original;
          btn.classList.remove('done');
        }, 1400);
      };

      if (navigator.clipboard && navigator.clipboard.writeText) {
        navigator.clipboard.writeText(text).then(done, fallback);
      } else {
        fallback();
      }

      // clipboard API를 못 쓰는 브라우저(구형·http)용 대체 경로
      function fallback() {
        var ta = document.createElement('textarea');
        ta.value = text;
        ta.setAttribute('readonly', '');
        ta.style.position = 'fixed';
        ta.style.opacity = '0';
        document.body.appendChild(ta);
        ta.select();
        try { document.execCommand('copy'); done(); } catch (e) { /* 무시 */ }
        document.body.removeChild(ta);
      }
    });
  });

  // ── 2. 목차 현재 위치 ───────────────────────────────────────
  var links = Array.prototype.slice.call(document.querySelectorAll('.toc-list a[href^="#"]'));
  if (!links.length || !('IntersectionObserver' in window)) return;

  var byId = {};
  var targets = [];
  links.forEach(function (a) {
    var el = document.getElementById(decodeURIComponent(a.getAttribute('href').slice(1)));
    if (el) { byId[el.id] = a; targets.push(el); }
  });

  var visible = new Set();
  var mark = function () {
    if (!visible.size) return;
    // 화면에 보이는 제목 중 문서 순서상 가장 앞선 것을 현재 위치로 본다.
    var current = targets.filter(function (t) { return visible.has(t.id); })[0];
    if (!current) return;
    links.forEach(function (a) { a.classList.remove('active'); });
    byId[current.id].classList.add('active');
  };

  var io = new IntersectionObserver(function (entries) {
    entries.forEach(function (e) {
      if (e.isIntersecting) visible.add(e.target.id);
      else visible.delete(e.target.id);
    });
    mark();
  }, { rootMargin: '-70px 0px -70% 0px' });

  targets.forEach(function (t) { io.observe(t); });
})();
