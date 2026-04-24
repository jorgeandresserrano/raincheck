document.addEventListener('DOMContentLoaded', () => {
  const state = {
    screen: 'onboarding',
    scenario: 'safe',
    horizon: 24,
    tolerance: 2,
    defaultHorizon: 24,
    location: 'San Francisco, CA',
    detailsOpen: false,
  };

  const scenarios = {
    safe: {
      unsafe: false,
      icon: 'ph-fill ph-sun',
      eyebrow: 'Current recommendation',
      title: 'Safe to wash',
      subtitle: (hours) => `Low precipitation risk for the next ${hours} hours.`,
      reason: 'Only a light chance of drizzle late tonight.',
      validUntil: 'Valid until 8:00 PM',
      nextRain: 'No rain expected',
      confidence: 'High',
      disclaimer: 'Recommendation based on the latest forecast. Conditions can still change.',
      sheetTitle: 'Why RainCheck says it is safe.',
      timeline: [
        { time: 'Now', label: 'Clear', chance: '5%' },
        { time: '3 PM', label: 'Dry', chance: '8%' },
        { time: '6 PM', label: 'Still dry', chance: '12%' },
        { time: '10 PM', label: 'Possible drizzle', chance: '18%' },
      ],
    },
    notRecommended: {
      unsafe: true,
      icon: 'ph-fill ph-cloud-rain',
      eyebrow: 'Current recommendation',
      title: 'Not recommended',
      subtitle: (hours) =>
        hours <= 12
          ? `Rain expected within the next ${hours} hours.`
          : `High chance of rain during this ${hours} hour window.`,
      reason: 'Steady rain looks likely before the wash window is over.',
      validUntil: 'Forecast shifts at 4:00 PM',
      nextRain: 'Rain starts in 3 hours',
      confidence: 'High',
      disclaimer: 'Waiting is safer here. Even light rain would likely undo the wash.',
      sheetTitle: 'Why RainCheck says not to wash now.',
      timeline: [
        { time: 'Now', label: 'Dry for now', chance: '18%' },
        { time: '2 PM', label: 'Clouds build', chance: '35%' },
        { time: '4 PM', label: 'Showers likely', chance: '58%' },
        { time: '7 PM', label: 'Rain expected', chance: '76%' },
      ],
    },
    loading: {
      unsafe: false,
      icon: 'ph ph-spinner-gap',
      eyebrow: 'Refreshing forecast',
      title: 'Checking the forecast',
      subtitle: () => 'Pulling the latest hourly outlook for your selected wash window.',
      reason: 'Forecast data is refreshing.',
      validUntil: 'One moment',
      nextRain: 'Updating forecast',
      confidence: 'Pending',
      disclaimer: 'This loading state lets us review how the app behaves while forecast data is being fetched.',
      sheetTitle: 'Loading state',
      timeline: [
        { time: 'Now', label: 'Fetching', chance: '--' },
      ],
    },
    empty: {
      unsafe: false,
      icon: 'ph ph-map-trifold',
      eyebrow: 'Missing context',
      title: 'Pick a location to start',
      subtitle: () => 'RainCheck needs a place before it can recommend whether today is a good wash day.',
      reason: 'No location is selected yet.',
      validUntil: 'Location needed',
      nextRain: 'Unavailable',
      confidence: 'N/A',
      disclaimer: 'This empty state appears before a location is chosen or when the user clears it.',
      sheetTitle: 'Empty state',
      timeline: [
        { time: 'Step 1', label: 'Set location', chance: '--' },
      ],
    },
    offline: {
      unsafe: true,
      icon: 'ph ph-wifi-slash',
      eyebrow: 'Connection issue',
      title: 'Offline right now',
      subtitle: () => 'We cannot refresh the forecast, so this recommendation is temporarily unavailable.',
      reason: 'No network connection for current forecast data.',
      validUntil: 'Reconnect to refresh',
      nextRain: 'Unknown while offline',
      confidence: 'Unavailable',
      disclaimer: 'The app should be explicit when it cannot confidently recommend washing.',
      sheetTitle: 'Offline state',
      timeline: [
        { time: 'Now', label: 'Offline', chance: '--' },
      ],
    },
    error: {
      unsafe: true,
      icon: 'ph ph-warning-circle',
      eyebrow: 'Something went wrong',
      title: 'Forecast unavailable',
      subtitle: () => 'We hit a problem while checking conditions. Try again in a moment.',
      reason: 'Forecast provider returned an error.',
      validUntil: 'Retry needed',
      nextRain: 'Unavailable',
      confidence: 'Unavailable',
      disclaimer: 'This state should keep the product calm and clear instead of technical or alarming.',
      sheetTitle: 'Error state',
      timeline: [
        { time: 'Now', label: 'Retry later', chance: '--' },
      ],
    },
  };

  const forecastByHorizon = {
    6: { pop: '10%', volume: '0.0 mm' },
    12: { pop: '18%', volume: '0.4 mm' },
    24: { pop: '45%', volume: '1.2 mm' },
    48: { pop: '80%', volume: '5.5 mm' },
  };

  const toleranceLabels = {
    1: 'Conservative',
    2: 'Standard',
    3: 'Flexible',
  };

  const screenPills = document.querySelectorAll('.screen-pill');
  const appViews = document.querySelectorAll('.app-view');
  const navButtons = document.querySelectorAll('[data-nav-target]');
  const timeSegments = document.querySelectorAll('#time-window .segment');
  const defaultSegments = document.querySelectorAll('#default-horizon .segment');
  const tolerancePills = document.querySelectorAll('#tolerance-presets .preset-pill');
  const settingsPresets = document.querySelectorAll('#settings-presets .preset-option');
  const scenarioChips = document.querySelectorAll('.scenario-chip');

  const appContainer = document.getElementById('app-container');
  const locationLabel = document.getElementById('location-label');
  const toleranceLabel = document.getElementById('tolerance-label');
  const statusIcon = document.getElementById('status-icon');
  const statusEyebrow = document.getElementById('status-eyebrow');
  const statusTitle = document.getElementById('status-title');
  const statusSubtitle = document.getElementById('status-subtitle');
  const validUntil = document.getElementById('valid-until');
  const nextRain = document.getElementById('next-rain');
  const reasonCopy = document.getElementById('reason-copy');
  const popVal = document.getElementById('pop-val');
  const volVal = document.getElementById('vol-val');
  const confidenceVal = document.getElementById('confidence-val');
  const disclaimerCopy = document.getElementById('disclaimer-copy');

  const detailsTrigger = document.getElementById('details-trigger');
  const detailSheet = document.getElementById('detail-sheet');
  const sheetBackdrop = document.getElementById('sheet-backdrop');
  const closeSheet = document.getElementById('close-sheet');
  const sheetTitle = document.getElementById('sheet-title');
  const sheetReason = document.getElementById('sheet-reason');
  const sheetDisclaimer = document.getElementById('sheet-disclaimer');
  const timelineList = document.getElementById('timeline-list');

  const useLocationBtn = document.getElementById('use-location-btn');
  const manualEntryBtn = document.getElementById('manual-entry-btn');
  const manualEntryCard = document.getElementById('manual-entry-card');
  const manualCityInput = document.getElementById('manual-city');
  const saveCityBtn = document.getElementById('save-city-btn');

  const editLocationBtn = document.getElementById('edit-location-btn');
  const settingsLocationCard = document.getElementById('settings-location-card');
  const settingsCityInput = document.getElementById('settings-city');
  const updateLocationBtn = document.getElementById('update-location-btn');

  function renderScreen() {
    appContainer.dataset.screen = state.screen;
    screenPills.forEach((pill) => {
      pill.classList.toggle('active', pill.dataset.screen === state.screen);
    });
    appViews.forEach((view) => {
      view.classList.toggle('active', view.dataset.view === state.screen);
    });
  }

  function renderScenario() {
    const scenario = scenarios[state.scenario];
    const horizonData = forecastByHorizon[state.horizon];

    appContainer.dataset.scenario = state.scenario;
    appContainer.classList.toggle('is-unsafe', scenario.unsafe);

    locationLabel.textContent = state.location;
    toleranceLabel.textContent = toleranceLabels[state.tolerance];
    statusIcon.innerHTML = `<i class="${scenario.icon}"></i>`;
    statusEyebrow.textContent = scenario.eyebrow;
    statusTitle.textContent = scenario.title;
    statusSubtitle.textContent = scenario.subtitle(state.horizon);
    validUntil.textContent = scenario.validUntil;
    nextRain.textContent = scenario.nextRain;
    reasonCopy.textContent = scenario.reason;
    confidenceVal.textContent = scenario.confidence;
    disclaimerCopy.textContent = scenario.disclaimer;
    popVal.textContent = horizonData.pop;
    volVal.textContent = horizonData.volume;

    sheetTitle.textContent = scenario.sheetTitle;
    sheetReason.textContent = scenario.reason;
    sheetDisclaimer.textContent = scenario.disclaimer;
    timelineList.innerHTML = scenario.timeline
      .map((item) => `
        <article class="timeline-item">
          <span>${item.time}</span>
          <strong>${item.label}</strong>
          <small>${item.chance}</small>
        </article>
      `)
      .join('');

    scenarioChips.forEach((chip) => {
      chip.classList.toggle('active', chip.dataset.scenario === state.scenario);
    });
  }

  function renderControls() {
    timeSegments.forEach((button) => {
      button.classList.toggle('active', Number(button.dataset.val) === state.horizon);
    });

    defaultSegments.forEach((button) => {
      button.classList.toggle('active', Number(button.dataset.defaultVal) === state.defaultHorizon);
    });

    tolerancePills.forEach((button) => {
      button.classList.toggle('active', Number(button.dataset.preset) === state.tolerance);
    });

    settingsPresets.forEach((button) => {
      button.classList.toggle('active', Number(button.dataset.settingsPreset) === state.tolerance);
    });
  }

  function renderDetailsSheet() {
    detailSheet.classList.toggle('hidden', !state.detailsOpen);
    sheetBackdrop.classList.toggle('hidden', !state.detailsOpen);
  }

  function goToScreen(screen) {
    state.screen = screen;
    state.detailsOpen = false;
    renderScreen();
    renderDetailsSheet();
  }

  function setLocation(nextLocation) {
    state.location = nextLocation.trim() || state.location;
    manualCityInput.value = state.location;
    settingsCityInput.value = state.location;
    renderScenario();
  }

  screenPills.forEach((pill) => {
    pill.addEventListener('click', () => {
      goToScreen(pill.dataset.screen);
    });
  });

  navButtons.forEach((button) => {
    button.addEventListener('click', () => {
      goToScreen(button.dataset.navTarget);
    });
  });

  timeSegments.forEach((button) => {
    button.addEventListener('click', () => {
      state.horizon = Number(button.dataset.val);
      renderControls();
      renderScenario();
    });
  });

  defaultSegments.forEach((button) => {
    button.addEventListener('click', () => {
      state.defaultHorizon = Number(button.dataset.defaultVal);
      state.horizon = state.defaultHorizon;
      renderControls();
      renderScenario();
    });
  });

  tolerancePills.forEach((button) => {
    button.addEventListener('click', () => {
      state.tolerance = Number(button.dataset.preset);
      renderControls();
    });
  });

  settingsPresets.forEach((button) => {
    button.addEventListener('click', () => {
      state.tolerance = Number(button.dataset.settingsPreset);
      renderControls();
    });
  });

  scenarioChips.forEach((button) => {
    button.addEventListener('click', () => {
      state.scenario = button.dataset.scenario;
      renderScenario();
    });
  });

  detailsTrigger.addEventListener('click', () => {
    state.detailsOpen = true;
    renderDetailsSheet();
  });

  closeSheet.addEventListener('click', () => {
    state.detailsOpen = false;
    renderDetailsSheet();
  });

  sheetBackdrop.addEventListener('click', () => {
    state.detailsOpen = false;
    renderDetailsSheet();
  });

  manualEntryBtn.addEventListener('click', () => {
    manualEntryCard.classList.toggle('hidden');
  });

  useLocationBtn.addEventListener('click', () => {
    setLocation('Current Location');
    state.scenario = 'safe';
    goToScreen('home');
    renderScenario();
  });

  saveCityBtn.addEventListener('click', () => {
    setLocation(manualCityInput.value);
    state.scenario = 'safe';
    goToScreen('home');
    renderScenario();
  });

  editLocationBtn.addEventListener('click', () => {
    settingsLocationCard.classList.toggle('hidden');
  });

  updateLocationBtn.addEventListener('click', () => {
    setLocation(settingsCityInput.value);
    settingsLocationCard.classList.add('hidden');
  });

  renderScreen();
  renderControls();
  renderScenario();
  renderDetailsSheet();
});
