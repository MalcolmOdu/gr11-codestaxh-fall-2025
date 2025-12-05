const CODESTAXH_URL = 'https://gr11-codestaxh-fall-2025.web.app/';

// State
let authToken = null;

// Initialization
document.addEventListener('DOMContentLoaded', async () => {
  // Check auth status
  authToken = await getAuthToken();
  updateUI();

  // Event listeners
  document.getElementById('signInBtn').addEventListener('click', handleSignIn);
  document.getElementById('signOutBtn').addEventListener('click', handleSignOut);
  document.getElementById('openAppBtn').addEventListener('click', () => {
    chrome.tabs.create({ url: CODESTAXH_URL });
  });
});

async function getAuthToken() {
  const result = await chrome.storage.local.get('authToken');
  return result.authToken || null;
}

async function handleSignIn() {
  try {
    // Open auth page in new tab
    const authUrl = `${CODESTAXH_URL}extension-auth`;
    const authTab = await chrome.tabs.create({ url: authUrl });

    // Listen for URL changes in that tab to detect token
    const listener = (tabId, changeInfo, tab) => {
      // Only watch the auth tab
      if (tabId !== authTab.id) return;

      // Check if page loaded completely
      if (changeInfo.status === 'complete' && tab.url) {
        try {
          const url = new URL(tab.url);
          const token = url.searchParams.get('token');
          const status = url.searchParams.get('status');


          if (token && status === 'success') {
            console.log('Token received from auth page');

            // Save token
            chrome.storage.local.set({ authToken: token }, () => {
              console.log('Token saved to storage');
            });

            // Close auth tab after short delay
            setTimeout(() => {
              chrome.tabs.remove(tabId);
              chrome.tabs.onUpdated.removeListener(listener);
            }, 1500);

            authToken = token;
            updateUI();
          }
        } catch (error) {
          console.error('Error parsing URL:', error);
        }
      }
    };

    // Add the listener
    chrome.tabs.onUpdated.addListener(listener);

    // Clean up listener after 5 minutes (timeout)
    setTimeout(() => {
      chrome.tabs.onUpdated.removeListener(listener);
    }, 5 * 60 * 1000);

    window.close();

  } catch (error) {
    console.error('Sign in error:', error);
    alert('Failed to open sign in page');
  }
}

async function handleSignOut() {
  try {
    await chrome.storage.local.remove('authToken');
    authToken = null;
    updateUI();
  } catch (error) {
    console.error('Sign out error:', error);
  }
}

function updateUI() {
  const loggedOutState = document.getElementById('loggedOutState');
  const loggedInState = document.getElementById('loggedInState');
  const actionsSection = document.getElementById('actionsSection');
  const instructionsSection = document.getElementById('instructionsSection');

  if (authToken) {
    // Logged in
    loggedOutState.style.display = 'none';
    loggedInState.style.display = 'flex';
    actionsSection.style.display = 'flex';
    instructionsSection.style.display = 'block';

    getUserInfo();
  } else {
    // Logged out
    loggedOutState.style.display = 'flex';
    loggedInState.style.display = 'none';
    actionsSection.style.display = 'none';
    instructionsSection.style.display = 'none';
  }
}

async function getUserInfo() {
  try {
    // Decode JWT to get email
    const payload = authToken.split('.')[1];
    const decoded = JSON.parse(atob(payload));

    document.getElementById('userEmail').textContent = decoded.email || 'User';
    document.getElementById('userStats').textContent = 'Extension ready';
  } catch (error) {
    document.getElementById('userEmail').textContent = 'User';
    document.getElementById('userStats').textContent = 'Extension ready';
  }
}

// Listen for storage changes (in case token set in another window)
chrome.storage.onChanged.addListener((changes, areaName) => {
  if (areaName === 'local' && changes.authToken) {
    authToken = changes.authToken.newValue;
    updateUI();
  }
});

console.log('CodeStaxh extension popup loaded');