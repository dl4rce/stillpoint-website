/* Illustrative routing, not a scheduler or backend. Own only this section's finite flows. */
(() => {
  'use strict';
  const root = document.querySelector('#distributed-context');
  if (!root) return;
  const scene = root.querySelector('.dc-scene');
  const svg = root.querySelector('.dc-connections');
  const rails = root.querySelector('.dc-rails');
  const packets = root.querySelector('.dc-packets');
  const controls = root.querySelector('.dc-controls');
  const buttons = [...root.querySelectorAll('[data-dc-scenario]')];
  const replay = root.querySelector('#dc-replay');
  const caption = root.querySelector('#dc-caption');
  const note = root.querySelector('#dc-motion-note');
  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)');
  // Match the viewport breakpoint in distributed-context.css, not the padded scene width.
  const stackedLayout = window.matchMedia('(max-width: 640px)');
  const ns = 'http://www.w3.org/2000/svg';
  let selected = 'nas';
  let inView = false;
  let animations = [];
  let routePaths = [];
  // These explicit assumptions are explanatory branches, never fabricated telemetry.
  const scenarios = {
    memory: {
      title: '01 / Reuse state already in memory', engine: 'a', source: 'cpu-a',
      caption: 'Assume A is eligible, idle and has both components in CPU memory. A host-to-GPU transfer makes that state executable. A GPU-resident hit would skip that transfer entirely. No SSD or NAS access is needed; memory residency never bypasses the manifest gates.',
      outcome: 'CPU → GPU · memory hit', a: 'Idle · CPU hit', vault: 'Not needed for this request'
    },
    ssd: {
      title: '02 / Restore from node-local SSD', engine: 'a', source: 'ssd-a',
      caption: 'Assume A is eligible and idle, with no memory hit but a matching artifact on its local SSD. Restore both components through CPU staging into GPU memory. The local route is assumed cheaper than eligible alternatives after queue, transfer, restore and remaining prefill are considered.',
      outcome: 'Local SSD → CPU → GPU', a: 'Idle · local artifact', vault: 'Not needed for this request'
    },
    nas: {
      title: '03 / Restore from the shared vault', engine: 'b', source: 'vault',
      caption: 'Assume no eligible engine has a local copy, and the NAS has a current, authorized, compatible artifact. Engine B is assumed to have the lowest estimated total cost. Both GDN and FA KV move from NAS through CPU staging into GPU memory; execution stays on B.',
      outcome: 'NAS → CPU → GPU · restored', b: 'Idle · selected', vault: 'Matching artifact available'
    },
    busy: {
      title: '04 / The warmest engine need not win', engine: 'b', source: 'vault',
      caption: 'Assume A has a GPU-resident match but is busy. B is eligible and idle; a matching NAS restore plus remaining work is assumed cheaper than waiting for A. Route the task to B and transfer both components from the vault. Warmth is one cost input, not an unconditional preference.',
      outcome: 'Idle B + NAS beats waiting', a: 'Busy · GPU hit', b: 'Idle · selected', vault: 'Restore to B, not busy A'
    },
    changed: {
      title: '05 / Changed knowledge means a new artifact', engine: 'c', source: null,
      caption: 'Assume the task’s working set changed and its new canonical prefix was frozen at a turn boundary. The old artifact fails freshness / exact-prefix validation and cannot be reused for this request. Authorized, compatible engine C cold-compiles the new prefix. No stale state is transferred or spliced; a new artifact may be persisted after validation.',
      outcome: 'New prefix → cold compile', c: 'Eligible · cold compile', vault: 'Old artifact rejected for reuse', gate: 'Old artifact rejected · compile new prefix'
    },
    offline: {
      title: '06 / Storage failure must not weaken correctness', engine: 'a', source: 'ssd-a',
      caption: 'Assume NAS is unreachable but A has a locally verifiable, current, authorized and compatible SSD artifact. Restore locally without NAS. If no safe local match exists, cold-compile from authorized current source when available; otherwise fail closed. Never bypass the gates or accept a stale artifact just to keep running.',
      outcome: 'Safe local restore · no NAS', a: 'Local artifact verified', vault: 'Unavailable · no transfer attempted', gate: 'Local manifest verified · gates unchanged'
    }
  };
  const make = (tag, attributes) => {
    const element = document.createElementNS(ns, tag);
    Object.entries(attributes).forEach(([key, value]) => element.setAttribute(key, value));
    return element;
  };
  const cancel = () => { animations.forEach(animation => animation.cancel()); animations = []; };
  const motionAllowed = () => !reduced.matches && !document.hidden && inView && document.documentElement.classList.contains('motion-enabled');
  const syncMotion = () => {
    if (reduced.matches) cancel();
    animations.forEach(animation => {
      if (animation.playState === 'finished' || animation.playState === 'idle') return;
      if (motionAllowed()) animation.play(); else animation.pause();
    });
    note.textContent = reduced.matches ? 'Reduced motion: route and caption update instantly; packets stay static.'
      : motionAllowed() ? 'User-triggered, finite packet flow. Illustrative pace, not transfer timing.'
        : 'Motion paused or offscreen. Route and caption still update; replay never overrides global Pause.';
  };
  const port = (id, side) => {
    const box = scene.querySelector(`[data-dc-port="${id}"]`).getBoundingClientRect();
    const bounds = scene.getBoundingClientRect();
    return { x: (side === 'left' ? box.left : side === 'right' ? box.right : box.left + box.width / 2) - bounds.left,
      y: (side === 'top' ? box.top : side === 'bottom' ? box.bottom : box.top + box.height / 2) - bounds.top };
  };
  const connect = (from, to, kind, active, gutter) => {
    const mobile = stackedLayout.matches;
    let start, end, points;
    if (kind === 'control') {
      start = port(from, mobile ? 'bottom' : 'right'); end = port(to, mobile ? 'top' : 'left');
      points = [start, end];
    } else if (kind === 'dispatch') {
      start = port(from, 'bottom'); end = port(to, 'top');
      const y = start.y + 22;
      if (mobile) {
        const x = scene.clientWidth - 10;
        points = [start, { x: start.x, y }, { x, y }, { x, y: end.y - 16 }, { x: end.x, y: end.y - 16 }, end];
      } else points = [start, { x: start.x, y }, { x: end.x, y }, end];
    } else {
      // State rails run OUTSIDE the engine enclosure, so packet motion remains visible.
      start = port(from, from === 'vault' ? 'top' : 'left'); end = port(to, 'left');
      const x = gutter === undefined ? end.x - 24 : gutter;
      points = [start, { x, y: start.y }, { x, y: end.y }, end];
    }
    const d = points.map((point, index) => `${index ? 'L' : 'M'} ${point.x} ${point.y}`).join(' ');
    const path = make('path', { d, class: `dc-rail${active ? ' is-active' : ''}${kind === 'state' ? ' is-state' : ''}`, 'stroke-linejoin': 'round', 'stroke-linecap': 'round' });
    rails.append(path);
    if (active) routePaths.push({ path, kind });
  };
  const draw = () => {
    cancel(); rails.replaceChildren(); packets.replaceChildren(); routePaths = [];
    const state = scenarios[selected];
    svg.setAttribute('viewBox', `0 0 ${scene.clientWidth || 1000} ${scene.clientHeight || 1000}`);
    connect('task', 'gates', 'control', true);
    connect('gates', 'router', 'control', true);
    ['a', 'b', 'c'].forEach(engine => connect('router', `engine-${engine}`, 'dispatch', engine === state.engine));
    if (state.source) {
      const cpu = `cpu-${state.engine}`;
      if (state.source !== cpu) connect(state.source, cpu, 'state', true);
      connect(cpu, `gpu-${state.engine}`, 'state', true);
    }
  };
  const play = () => {
    cancel(); packets.replaceChildren();
    if (reduced.matches || typeof Element.prototype.animate !== 'function') { syncMotion(); return; }
    // One pass: request -> gates -> router -> replica, THEN both state components.
    // Durations are presentation choices only and are never displayed as measurements.
    routePaths.forEach(({ path, kind }, index) => {
      if (typeof path.getTotalLength !== 'function') return;
      const length = path.getTotalLength();
      const pair = kind === 'state' ? ['is-gdn', 'is-kv'] : [selected === 'changed' ? 'is-cold' : 'is-request'];
      pair.forEach((component, componentIndex) => {
        const packet = make('circle', { r: kind === 'state' ? 4 : 3, class: `dc-packet ${component}` });
        packets.append(packet);
        const frames = Array.from({ length: 41 }, (_, step) => {
          const point = path.getPointAtLength(length * step / 40);
          return { transform: `translate(${point.x + (componentIndex ? 5 : -2)}px, ${point.y + (componentIndex ? 5 : -2)}px)`, opacity: step === 0 || step === 40 ? 0 : 1, offset: step / 40 };
        });
        const animation = packet.animate(frames, { duration: 950, delay: index * 850, easing: 'linear', fill: 'both', iterations: 1 });
        animation.pause(); animations.push(animation);
      });
    });
    syncMotion();
  };
  const select = (key, animate) => {
    if (!Object.hasOwn(scenarios, key)) return;
    selected = key;
    const state = scenarios[key];
    scene.dataset.scenario = key;
    buttons.forEach(button => button.setAttribute('aria-pressed', String(button.dataset.dcScenario === key)));
    caption.querySelector('strong').textContent = state.title;
    caption.querySelector('span').textContent = state.caption;
    root.querySelector('.dc-gate-result').textContent = state.gate || 'Matching artifact admitted';
    root.querySelector('.dc-vault-status').textContent = state.vault;
    root.querySelectorAll('[data-engine]').forEach(engine => {
      const id = engine.dataset.engine;
      engine.classList.toggle('is-selected', id === state.engine);
      engine.querySelector('.dc-node-status').textContent = state[id] || 'Eligible · not selected';
      engine.querySelector('.dc-outcome').textContent = id === state.engine ? state.outcome : key === 'busy' && id === 'a' ? 'Warm state retained · request sent to B' : 'Available candidate';
    });
    draw();
    if (animate) play(); else syncMotion();
  };
  controls.hidden = false; replay.hidden = false;
  buttons.forEach(button => button.addEventListener('click', () => select(button.dataset.dcScenario, true)));
  replay.addEventListener('click', () => select(selected, true));
  reduced.addEventListener('change', syncMotion);
  stackedLayout.addEventListener('change', () => { draw(); syncMotion(); });
  document.addEventListener('visibilitychange', syncMotion);
  // Consume the EXISTING page-wide motion state without changing its controller or evidence.
  new MutationObserver(syncMotion).observe(document.documentElement, { attributes: true, attributeFilter: ['class'] });
  if ('IntersectionObserver' in window) {
    new IntersectionObserver(entries => { inView = entries[0].isIntersecting; syncMotion(); }, { threshold: 0 }).observe(scene);
  } else {
    const visibility = () => { const box = scene.getBoundingClientRect(); inView = box.bottom > 0 && box.top < window.innerHeight; syncMotion(); };
    window.addEventListener('scroll', visibility, { passive: true });
    window.addEventListener('resize', visibility); visibility();
  }
  if ('ResizeObserver' in window) new ResizeObserver(() => { draw(); syncMotion(); }).observe(scene);
  else window.addEventListener('resize', () => { draw(); syncMotion(); });
  select(selected, false); // No autoplay: the static NAS example is complete without motion.
})();
