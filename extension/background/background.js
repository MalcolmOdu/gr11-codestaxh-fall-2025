const FIREBASE_CONFIG = {
  apiKey: 'AIzaSyDMHoVDJ3pplDNOnQ6MT4H47-StFlvE76I',
  projectId: 'gr11-codestaxh-fall-2025',
  appId: '1:156138335674:web:bbb30832bd61f97573c183'
};

const FIRESTORE_URL = `https://firestore.googleapis.com/v1/projects/${FIREBASE_CONFIG.projectId}/databases/(default)/documents`;


chrome.runtime.onMessage.addListener((request, sender, sendResponse) => {
  if (request.action === 'stashSnippet') {
    handleSaveSnippet(request.data)
      .then(() => sendResponse({ success: true }))
      .catch((error) => sendResponse({ success: false, error: error.message }));
    return true; // Keep channel open for async response
  }
});

// Save snippet to firestore
async function handleSaveSnippet(snippetData) {
  try {
    // Get auth token
    const authToken = await getAuthToken();

    if (!authToken) {
      throw new Error('Not authenticated. Please sign in via extension popup.');
    }

    // Generate snippet ID
    const snippetId = generateId();

    // Prepare Firestore document
    const firestoreDoc = {
      fields: {
        id: { stringValue: snippetId },
        title: { stringValue: createTitleFromSource(snippetData.sourceTitle, snippetData.language) },
        code: { stringValue: snippetData.code },
        language: { stringValue: snippetData.language },
        tags: {
          arrayValue: {
            values: [
              { stringValue: snippetData.language },
              { stringValue: 'imported' },
              { stringValue: 'browser-extension' }
            ]
          }
        },
        author: { stringValue: await getUserEmail(authToken) || 'Extension User' },
        upvote: { integerValue: '0' },
        dateAdded: { timestampValue: new Date().toISOString() },
        sourceUrl: { stringValue: snippetData.sourceUrl || '' },
        description: { stringValue: `Imported from ${new URL(snippetData.sourceUrl).hostname}` }
      }
    };

    // Save to Firestore
    const response = await fetch(
      `${FIRESTORE_URL}/snippets/${snippetId}?key=${FIREBASE_CONFIG.apiKey}`,
      {
        method: 'PATCH',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': `Bearer ${authToken}`
        },
        body: JSON.stringify(firestoreDoc)
      }
    );

    if (!response.ok) {
      const error = await response.json();
      throw new Error(error.error?.message || 'Firestore write failed');
    }

    console.log('Snippet saved successfully:', snippetId);

    // Show notification
    chrome.notifications.create({
      type: 'basic',
      iconUrl: 'icons/codestaxh-icon48.png',
      title: 'CodeStaxh',
      message: `Snippet saved: ${snippetData.language}`,
      priority: 1
    });

    return snippetId;

  } catch (error) {
    console.error('Stash error:', error);

    // Show error notification
    chrome.notifications.create({
      type: 'basic',
      iconUrl: 'icons/codestaxh-icon48.png',
      title: 'CodeStaxh - Error',
      message: error.message || 'Failed to stash snippet',
      priority: 2
    });

    throw error;
  }
}

// AUTH TOKEN MANAGEMENT
async function getAuthToken() {
  try {
    const result = await chrome.storage.local.get('authToken');
    return result.authToken || null;
  } catch (error) {
    console.error('Error getting auth token:', error);
    return null;
  }
}

async function getUserEmail(authToken) {
  try {
    const payload = authToken.split('.')[1];
    const decoded = JSON.parse(atob(payload));
    return decoded.email || null;
  } catch (error) {
    return null;
  }
}

function generateId() {
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
    const r = Math.random() * 16 | 0;
    const v = c === 'x' ? r : (r & 0x3 | 0x8);
    return v.toString(16);
  });
}

function createTitleFromSource(pageTitle, language) {
  // Extract meaningful title from page
  let title = pageTitle;

  // Clean up Stack Overflow and github titles
  title = title.replace(' - Stack Overflow', '');
  title = title.replace(/· GitHub$/, '');

  // Limit length
  if (title.length > 60) {
    title = title.substring(0, 57) + '...';
  }

  return `${language} - ${title}`;
}

console.log('CodeStaxh background service worker initialized');
console.log('Project ID:', FIREBASE_CONFIG.projectId)