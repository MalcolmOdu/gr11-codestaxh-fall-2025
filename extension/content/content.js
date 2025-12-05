const CODESTAXH_URL = 'https://gr11-codestaxh-fall-2025.web.app/';

function injectSaveButtons() {
  // Find all code blocks on the page
  const codeBlocks = document.querySelectorAll([
    'pre code',                    // Stack Overflow, GitHub
    'pre',                         // General pre tags
    '.highlight',                  // GitHub highlighted code
    'div[class*="code"]',         // Various code containers
    '.hljs',                       // highlight.js
    '.language-'                   // Prism.js
  ].join(', '));

  console.log('CodeStaxh: Found ${codeBlocks.length} code blocks');

  codeBlocks.forEach((block, index) => {
    // Skip if already has button
    if (block.dataset.codestaxhButton) return;
    block.dataset.codestaxhButton = 'true';

    // Find or create container
    const container = getOrCreateContainer(block);

    // Create save button
    const saveButton = createSaveButton(block, index);

    // Insert button
    container.appendChild(saveButton);
  });
}


function getOrCreateContainer(codeBlock) {
  // Look for existing toolbar/header
  const parent = codeBlock.parentElement;

  // Stack Overflow specific
  if (parent.classList.contains('s-code-block')) {
    let toolbar = parent.querySelector('.s-code-block-toolbar');
    if (!toolbar) {
      toolbar = document.createElement('div');
      toolbar.className = 's-code-block-toolbar';
      parent.insertBefore(toolbar, codeBlock);
    }
    return toolbar;
  }

  // GitHub specific
  if (parent.classList.contains('highlight')) {
    let toolbar = parent.querySelector('.codestaxh-toolbar');
    if (!toolbar) {
      toolbar = document.createElement('div');
      toolbar.className = 'codestaxh-toolbar';
      parent.insertBefore(toolbar, codeBlock);
    }
    return toolbar;
  }

  // Generic fallback - create wrapper
  let wrapper = codeBlock.parentElement;
  if (!wrapper.classList.contains('codestaxh-wrapper')) {
    wrapper = document.createElement('div');
    wrapper.className = 'codestaxh-wrapper';
    wrapper.style.position = 'relative';
    codeBlock.parentElement.insertBefore(wrapper, codeBlock);
    wrapper.appendChild(codeBlock);
  }

  return wrapper;
}


function createSaveButton(codeBlock, index) {
  const button = document.createElement('button');
  button.className = 'codestaxh-save-btn';
  button.innerHTML = `
    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
      <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
      <polyline points="17 21 17 13 7 13 7 21"></polyline>
      <polyline points="7 3 7 8 15 8"></polyline>
    </svg>
    <span>Stash to CodeStaxh</span>
  `;

  button.onclick = (e) => {
    e.preventDefault();
    e.stopPropagation();
    saveCodeSnippet(codeBlock, button);
  };

  return button;
}


async function saveCodeSnippet(codeBlock, button) {
  try {
    // Change button state
    button.disabled = true;
    button.classList.add('stashing');
    button.innerHTML = `
      <svg class="spinner" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10"></circle>
      </svg>
      <span>Stashing...</span>
    `;

    // Extract code
    const code = codeBlock.textContent || codeBlock.innerText;

    // Detect language
    const language = detectLanguage(codeBlock, code);

    // Get page context
    const pageTitle = document.title;
    const pageUrl = window.location.href;

    // Send to background script
    const response = await chrome.runtime.sendMessage({
      action: 'stashSnippet',
      data: {
        code: code.trim(),
        language: language,
        sourceTitle: pageTitle,
        sourceUrl: pageUrl,
        timestamp: new Date().toISOString()
      }
    });

    if (response.success) {
      // Success state
      button.classList.remove('stashing');
      button.classList.add('stashed');
      button.innerHTML = `
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <polyline points="20 6 9 17 4 12"></polyline>
        </svg>
        <span>Stashed!</span>
      `;

      // Reset after 2 seconds
      setTimeout(() => {
        button.disabled = false;
        button.classList.remove('stashed');
        button.innerHTML = `
          <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
            <polyline points="17 21 17 13 7 13 7 21"></polyline>
            <polyline points="7 3 7 8 15 8"></polyline>
          </svg>
          <span>Stash to CodeStaxh</span>
        `;
      }, 2000);
    } else {
      throw new Error(response.error || 'Failed to stash');
    }

  } catch (error) {
    console.error('Stash error:', error);

    // Error state
    button.classList.remove('stashing');
    button.classList.add('error');
    button.innerHTML = `
      <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
        <circle cx="12" cy="12" r="10"></circle>
        <line x1="15" y1="9" x2="9" y2="15"></line>
        <line x1="9" y1="9" x2="15" y2="15"></line>
      </svg>
      <span>Error - Try again</span>
    `;

    // Reset after 3 seconds
    setTimeout(() => {
      button.disabled = false;
      button.classList.remove('error');
      button.innerHTML = `
        <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
          <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
          <polyline points="17 21 17 13 7 13 7 21"></polyline>
          <polyline points="7 3 7 8 15 8"></polyline>
        </svg>
        <span>Stash to CodeStaxh</span>
      `;
    }, 3000);
  }
}


function detectLanguage(codeBlock, code) {
  // Check class names
  const classes = codeBlock.className.toLowerCase();


  const languageMap = {
    'python': 'Python',
    'javascript': 'JavaScript',
    'js': 'JavaScript',
    'typescript': 'TypeScript',
    'ts': 'TypeScript',
    'java': 'Java',
    'cpp': 'C++',
    'c++': 'C++',
    'csharp': 'C#',
    'cs': 'C#',
    'dart': 'Dart',
    'go': 'Go',
    'rust': 'Rust',
    'ruby': 'Ruby',
    'php': 'PHP',
    'sql': 'SQL',
    'html': 'HTML',
    'css': 'CSS',
    'bash': 'Bash',
    'shell': 'Shell',
    'json': 'JSON',
    'yaml': 'YAML',
    'xml': 'XML'
  };

  // Check class names first
  for (const [key, value] of Object.entries(languageMap)) {
    if (classes.includes(key)) {
      return value;
    }
  }

  // Fallback: Simple heuristics
  if (code.includes('def ') || code.includes('import ')) return 'Python';
  if (code.includes('function ') || code.includes('const ') || code.includes('let ')) return 'JavaScript';
  if (code.includes('public class ')) return 'Java';
  if (code.includes('<?php')) return 'PHP';
  if (code.includes('SELECT ') || code.includes('FROM ')) return 'SQL';

  return 'Unknown';
}


// Run when page loads
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', injectSaveButtons);
} else {
  injectSaveButtons();
}

// Re-run when new content loads
const observer = new MutationObserver((mutations) => {
  // Debounce - only run if significant changes
  if (mutations.length > 5) {
    injectSaveButtons();
  }
});

observer.observe(document.body, {
  childList: true,
  subtree: true
});

// Listen for page navigation
let lastUrl = location.href;
new MutationObserver(() => {
  const url = location.href;
  if (url !== lastUrl) {
    lastUrl = url;
    setTimeout(injectSaveButtons, 1000); // Delay for content to load
  }
}).observe(document, { subtree: true, childList: true });

console.log('CodeStaxh extension loaded!');