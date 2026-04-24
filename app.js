document.addEventListener('DOMContentLoaded', () => {
  const container = document.getElementById('app-container');
  const timeSegments = document.querySelectorAll('.segment');
  const toleranceSlider = document.getElementById('tolerance-slider');
  const toleranceLabel = document.getElementById('tolerance-label');
  
  const statusIcon = document.getElementById('status-icon');
  const statusTitle = document.getElementById('status-title');
  const statusSubtitle = document.getElementById('status-subtitle');
  
  const popVal = document.getElementById('pop-val');
  const volVal = document.getElementById('vol-val');

  // State
  let currentTimeWindow = 24;
  let currentTolerance = 2; // 1: Low, 2: Med, 3: High

  // Dummy Forecast Data Logic
  // For prototyping, we'll map certain combinations to "Safe" or "Unsafe"
  function evaluateCondition() {
    let isSafe = true;
    let pop = 0; // Probability of precipitation
    let vol = 0; // Volume in mm

    // Simulate weather getting worse the further out we look
    if (currentTimeWindow === 6) {
      pop = 10;
      vol = 0.0;
    } else if (currentTimeWindow === 12) {
      pop = 20;
      vol = 0.5;
    } else if (currentTimeWindow === 24) {
      pop = 45;
      vol = 1.2;
    } else if (currentTimeWindow === 48) {
      pop = 80;
      vol = 5.5;
    }

    // Apply Tolerance
    // High tolerance = willing to accept more rain risk
    const popThreshold = currentTolerance === 1 ? 20 : currentTolerance === 2 ? 40 : 60;
    
    if (pop > popThreshold) {
      isSafe = false;
    }

    updateUI(isSafe, pop, vol);
  }

  function updateUI(isSafe, pop, vol) {
    popVal.innerText = `${pop}%`;
    volVal.innerText = `${vol} mm`;

    // Add a slight fade effect by resetting animation
    statusIcon.style.animation = 'none';
    statusIcon.offsetHeight; /* trigger reflow */
    statusIcon.style.animation = null; 

    if (isSafe) {
      container.classList.remove('unsafe');
      statusIcon.innerHTML = '<i class="ph-fill ph-sun"></i>';
      statusTitle.innerText = "Safe to wash";
      
      if (pop < 15) {
        statusSubtitle.innerText = `Clear skies expected for the next ${currentTimeWindow} hours.`;
      } else {
        statusSubtitle.innerText = `Low precipitation risk for the next ${currentTimeWindow} hours.`;
      }
    } else {
      container.classList.add('unsafe');
      statusIcon.innerHTML = '<i class="ph-fill ph-cloud-rain"></i>';
      statusTitle.innerText = "Not recommended";
      
      if (currentTimeWindow <= 12) {
        statusSubtitle.innerText = `Rain expected within the next ${currentTimeWindow} hours.`;
      } else {
        statusSubtitle.innerText = `High chance of rain during this ${currentTimeWindow} hour window.`;
      }
    }
  }

  // Event Listeners
  timeSegments.forEach(segment => {
    segment.addEventListener('click', (e) => {
      timeSegments.forEach(s => s.classList.remove('active'));
      e.target.classList.add('active');
      currentTimeWindow = parseInt(e.target.getAttribute('data-val'), 10);
      evaluateCondition();
    });
  });

  toleranceSlider.addEventListener('input', (e) => {
    currentTolerance = parseInt(e.target.value, 10);
    const labels = ["Low", "Medium", "High"];
    toleranceLabel.innerText = labels[currentTolerance - 1];
    evaluateCondition();
  });

  // Initial evaluation
  evaluateCondition();
});
