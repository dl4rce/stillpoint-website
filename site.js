/* Progressive enhancement for a static research site. No backend, timers or tracking. */
(() => {
  'use strict';
  document.documentElement.classList.add('js');
  const navToggle = document.querySelector('.nav-toggle');
  const links = document.querySelector('#site-links');
  if (navToggle && links) {
    navToggle.hidden = false;
    const closeMenu = () => {
      navToggle.setAttribute('aria-expanded', 'false');
      links.classList.remove('is-open');
    };
    navToggle.addEventListener('click', () => {
      const open = navToggle.getAttribute('aria-expanded') !== 'true';
      navToggle.setAttribute('aria-expanded', String(open));
      links.classList.toggle('is-open', open);
    });
    links.addEventListener('click', event => {
      if (event.target.closest('a')) closeMenu();
    });
    document.addEventListener('keydown', event => {
      if (event.key === 'Escape' && navToggle.getAttribute('aria-expanded') === 'true') {
        closeMenu();
        navToggle.focus();
      }
    });
  }

  const reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)');
  const motionButton = document.querySelector('.motion-control');
  let motionEnabled = true;
  const animatedRegions = [...document.querySelectorAll('.context-scene, .memory-scene, .evidence-chart')];
  const running = new Map();
  const replayButton = document.querySelector('#replay-evidence');
  const chart = document.querySelector('.evidence-chart');
  // Own only our finite animations; CSS ambient motion uses the same visibility gate.
  const playFinite = (region, items) => {
    (running.get(region) || []).forEach(animation => animation.cancel());
    const animations = items.map(([element, frames, duration]) => {
      const animation = element.animate(frames, { duration, easing: 'linear', fill: 'both' });
      animation.pause();
      return animation;
    });
    running.set(region, animations);
    syncMotion();
  };
  const syncMotion = () => {
    const enabled = motionEnabled && !reduceMotion.matches && !document.hidden;
    document.documentElement.classList.toggle('motion-enabled', enabled);
    document.documentElement.classList.toggle('no-motion', !enabled);
    if (motionButton) {
      motionButton.setAttribute('aria-pressed', String(motionEnabled && !reduceMotion.matches));
      motionButton.textContent = reduceMotion.matches ? 'Animations off · reduced motion' : motionEnabled ? 'Pause animations' : 'Resume animations';
      motionButton.disabled = reduceMotion.matches;
    }
    if (replayButton) replayButton.disabled = !motionEnabled || reduceMotion.matches;
    running.forEach((animations, region) => {
      animations.forEach(animation => {
        if (reduceMotion.matches) animation.cancel();
        else if (animation.playState !== 'finished' && animation.playState !== 'idle') {
          if (enabled && region.classList.contains('in-view')) animation.play();
          else animation.pause();
        }
      });
    });
  };
  if (motionButton) {
    motionButton.hidden = false;
    motionButton.addEventListener('click', () => { motionEnabled = !motionEnabled; syncMotion(); });
  }
  reduceMotion.addEventListener('change', syncMotion);
  document.addEventListener('visibilitychange', syncMotion);
  syncMotion();
  const canAnimate = typeof Element.prototype.animate === 'function';
  let evidencePlayed = false;
  const replayEvidence = () => {
    if (!canAnimate || !chart || !motionEnabled || reduceMotion.matches) return;
    evidencePlayed = true;
    // Published measurements, one pixels-per-second scale, accelerated exactly 4×.
    playFinite(chart, [
      [chart.querySelector('.bar'), [{ transform: 'scaleX(0)' }, { transform: 'scaleX(1)' }], 27410 / 4],
      [chart.querySelector('.bar.restored'), [{ transform: 'scaleX(0)' }, { transform: 'scaleX(1)' }], 3600 / 4]
    ]);
  };
  if (replayButton && canAnimate) {
    replayButton.hidden = false;
    replayButton.addEventListener('click', replayEvidence);
  }
  const updateVisibility = (region, visible) => {
    region.classList.toggle('in-view', visible);
    if (region === chart && visible && !document.hidden && !evidencePlayed) replayEvidence();
    syncMotion();
  };
  if ('IntersectionObserver' in window) {
    const observer = new IntersectionObserver(entries => {
      entries.forEach(entry => updateVisibility(entry.target, entry.isIntersecting));
    }, { threshold: 0.15 });
    animatedRegions.forEach(region => observer.observe(region));
  } else {
    // Older browsers still stop offscreen animation without an observer polyfill.
    const checkVisibility = () => animatedRegions.forEach(region => {
      const rect = region.getBoundingClientRect();
      updateVisibility(region, rect.bottom > 0 && rect.top < window.innerHeight);
    });
    window.addEventListener('scroll', checkVisibility, { passive: true });
    window.addEventListener('resize', checkVisibility);
    checkVisibility();
  }

  const scene = document.querySelector('#context-scene');
  if (!scene) return;
  const states = {
    select: ['01 / Select a stable prefix', 'Choose a defined token sequence. Selection here explains the workflow; automatic working-set selection and eviction are roadmap goals. No checkpoint has been written.', 'Prefix selected · not compiled', 'Disk tier · no checkpoint'],
    compile: ['02 / Compile both forms of state', 'Read the prefix through the model. The GDN recurrent snapshot stays fixed in shape; full-attention KV grows with tokens. Change the illustrative prefix size to see the distinction.', 'Running engine · prefix compiled', 'Disk tier · no checkpoint'],
    persist: ['03 / Persist the standing place', 'Write the recurrent snapshot and full-attention KV to the disk tier at the accepted prefix boundary. Both components are needed for a correct hybrid restore.', 'Running engine · state stored', 'Disk checkpoint · both components stored'],
    restart: ['04 / Stop the engine, keep the checkpoint', 'The running engine and its in-memory state disappear. The disk checkpoint remains. PIN-0001 tested a full vLLM process restart, not a host reboot.', 'Engine stopped · memory cleared', 'Disk checkpoint · retained while engine is stopped'],
    restore: ['05 / Restore the same exact prefix', 'A new engine loads both components from disk for the matching prefix. The measured experiment recovered the exact buried key; changed prefixes require recompilation.', 'New engine · exact-prefix state restored', 'Disk checkpoint · available for reuse']
  };
  const title = document.querySelector('#step-title');
  const caption = document.querySelector('#step-caption');
  const engineLabel = scene.querySelector('.scene-label');
  const diskLabel = scene.querySelector('.disk-checkpoint strong');
  const buttons = [...document.querySelectorAll('[data-context-step]')];
  const volumeButton = document.querySelector('#prefix-volume');
  document.querySelector('.diagram-controls').hidden = false;
  const setStep = step => {
    const state = states[step];
    if (!state) return;
    (running.get(scene) || []).forEach(animation => animation.cancel());
    running.delete(scene);
    scene.dataset.step = step;
    if (canAnimate && !reduceMotion.matches && ['compile', 'persist', 'restore'].includes(step)) {
      const flows = [...scene.querySelectorAll('.state-flow')];
      const frames = step === 'compile'
        ? [{ top: '12%', opacity: 0 }, { top: '20%', opacity: 1, offset: 0.2 }, { top: '43%', opacity: 0 }]
        : step === 'persist'
          ? [{ top: '43%', opacity: 0 }, { top: '50%', opacity: 1, offset: 0.2 }, { top: '77%', opacity: 0 }]
          : [{ top: '77%', opacity: 0 }, { top: '68%', opacity: 1, offset: 0.2 }, { top: '43%', opacity: 0 }];
      playFinite(scene, flows.map(flow => [flow, frames, 1800]));
    }
    title.textContent = state[0];
    caption.textContent = state[1];
    engineLabel.textContent = state[2];
    diskLabel.textContent = state[3];
    buttons.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.contextStep === step)));
    volumeButton.disabled = step !== 'compile' && step !== 'select';
  };
  buttons.forEach(button => button.addEventListener('click', () => setStep(button.dataset.contextStep)));
  volumeButton.addEventListener('click', () => {
    const extended = scene.dataset.volume === 'short';
    scene.dataset.volume = extended ? 'extended' : 'short';
    volumeButton.textContent = extended ? 'Longer prefix' : 'Shorter prefix';
    volumeButton.setAttribute('aria-pressed', String(extended));
  });
  setStep('select');
})();
