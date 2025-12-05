// Find all code blocks on page
function addSaveButtons() {
  const codeBlocks = document.querySelectorAll('pre code, pre, .highlight, .code-block');

  codeBlocks.forEach((block, index) => {
    // Skip if button already added
    if (block.dataset.codestaxhButton) return;
    block.dataset.codestaxhButton = 'true';

    // Get parent container
    const parent = block.parentElement;
    if (parent.style.position !== 'absolute' && parent.style.position !== 'relative') {
      parent.style.position = 'relative';
    }

    // Create save button (initially hidden)
    const button = document.createElement('button');
    button.className = 'codestaxh-save-btn';
    button.innerHTML = `
      <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
        <path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/>
        <polyline points="17 21 17 13 7 13 7 21"/>
        <polyline points="7 3 7 8 15 8"/>
      </svg>
      Stash Snippet
    `;

    button.style.cssText = `
      position: absolute;
      top: 8px;
      right: 8px;
      padding: 6px 10px;
      background: linear-gradient(135deg, #6C63FF 0%, #00D9FF 100%);
      color: white;
      border: none;
      border-radius: 6px;
      cursor: pointer;
      font-size: 12px;
      font-weight: 600;
      font-family: -apple-system, system-ui, sans-serif;
      z-index: 9999;
      display: flex;
      align-items: center;
      gap: 6px;
      opacity: 0;
      transform: translateY(-4px);
      transition: all 0.2s ease;
      pointer-events: none;
      box-shadow: 0 2px 8px rgba(108, 99, 255, 0.3);
    `;

    //Button only appears when hovering over code block
    parent.addEventListener('mouseenter', () => {
      button.style.opacity = '1';
      button.style.transform = 'translateY(0)';
      button.style.pointerEvents = 'auto';
    });

    parent.addEventListener('mouseleave', () => {
      button.style.opacity = '0';
      button.style.transform = 'translateY(-4px)';
      button.style.pointerEvents = 'none';
    });

    // Hover effect on button itself
    button.addEventListener('mouseenter', () => {
      button.style.transform = 'translateY(0) scale(1.05)';
      button.style.boxShadow = '0 4px 12px rgba(108, 99, 255, 0.4)';
    });

    button.addEventListener('mouseleave', () => {
      button.style.transform = 'translateY(0) scale(1)';
      button.style.boxShadow = '0 2px 8px rgba(108, 99, 255, 0.3)';
    });

    // Click handler
    button.onclick = (e) => {
      e.stopPropagation();
      const code = block.textContent;
      const language = detectLanguage(block);
      saveSnippet(code, language);

      //Show saved state
      button.innerHTML = `
        <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
          <path d="M20 6L9 17l-5-5"/>
        </svg>
        Stashed!
      `;
      button.style.background = 'linear-gradient(135deg, #10B981 0%, #059669 100%)';

      // Reset after 2 seconds
      setTimeout(() => {
        button.innerHTML = `
          <svg width="16" height="16" viewBox="0 0 24 24" fill="currentColor">
            <path d="M19 21H5a2 2 0 01-2-2V5a2 2 0 012-2h11l5 5v11a2 2 0 01-2 2z"/>
            <polyline points="17 21 17 13 7 13 7 21"/>
            <polyline points="7 3 7 8 15 8"/>
          </svg>
          Stash Snippet
        `;
        button.style.background = 'linear-gradient(135deg, #6C63FF 0%, #00D9FF 100%)';
      }, 2000);
    };

    parent.insertBefore(button, block);
  });
}

function detectLanguage(codeBlock) {
  // Try to detect language from class names
  const classes = codeBlock.className;

  if (classes.includes('python') || classes.includes('lang-python')) return 'Python';
  if (classes.includes('javascript') || classes.includes('js') || classes.includes('lang-js')) return 'JavaScript';
  if (classes.includes('java') && !classes.includes('javascript')) return 'Java';
  if (classes.includes('cpp') || classes.includes('c++') || classes.includes('lang-cpp')) return 'C++';
  if (classes.includes('dart') || classes.includes('lang-dart')) return 'Dart';
  if (classes.includes('php') || classes.includes('lang-php')) return 'PHP';
  if (classes.includes('sql') || classes.includes('lang-sql')) return 'SQL';
  if (classes.includes('html') || classes.includes('lang-html')) return 'HTML';
  if (classes.includes('rust') || classes.includes('lang-rust')) return 'Rust';
  if (classes.includes('go') || classes.includes('golang')) return 'Go';
  if (classes.includes('kotlin') || classes.includes('lang-kotlin')) return 'Kotlin';
  if (classes.includes('swift') || classes.includes('lang-swift')) return 'Swift';
  if (classes.includes('ruby') || classes.includes('lang-ruby')) return 'Ruby';
  if (classes.includes('css') || classes.includes('lang-css')) return 'CSS';
  if (classes.includes('typescript') || classes.includes('ts')) return 'TypeScript';

  return 'Code';
}

function saveSnippet(code, language) {
  // Send to background script
  chrome.runtime.sendMessage({
    action: 'stashSnippet',
    code: code,
    language: language,
    url: window.location.href,
  }, (response) => {
    if (response && response.success) {
      console.log('Stashed to CodeStaxh!');
    } else {
      console.error('Error:', response?.error || 'Unknown error');
    }
  });
}

// Run when page loads
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', addSaveButtons);
} else {
  addSaveButtons();
}

// Re-run if page content changes (for SPAs like Stack Overflow)
const observer = new MutationObserver((mutations) => {
  // Debounce to avoid too many calls
  clearTimeout(observer.timeout);
  observer.timeout = setTimeout(addSaveButtons, 500);
});

observer.observe(document.body, {
  childList: true,
  subtree: true
});

//keyboard shortcut (Ctrl+Shift+S to save focused code block)
document.addEventListener('keydown', (e) => {
  if (e.ctrlKey && e.shiftKey && e.key === 'S') {
    e.preventDefault();

    // Find code block under cursor or first visible one
    const codeBlocks = document.querySelectorAll('pre code, pre, .highlight');
    if (codeBlocks.length > 0) {
      const firstBlock = codeBlocks[0];
      const code = firstBlock.textContent;
      const language = detectLanguage(firstBlock);
      saveSnippet(code, language);

      // Show toast notification
      showToast('Code stashed to CodeStaxh!');
    }
  }
});

function showToast(message) {
  const toast = document.createElement('div');
  toast.textContent = message;
  toast.style.cssText = `
    position: fixed;
    bottom: 20px;
    right: 20px;
    background: linear-gradient(135deg, #10B981 0%, #059669 100%);
    color: white;
    padding: 12px 20px;
    border-radius: 8px;
    font-family: -apple-system, system-ui, sans-serif;
    font-size: 14px;
    font-weight: 600;
    z-index: 999999;
    box-shadow: 0 4px 12px rgba(16, 185, 129, 0.3);
    animation: slideIn 0.3s ease;
  `;

  document.body.appendChild(toast);

  setTimeout(() => {
    toast.style.animation = 'slideOut 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 2000);
}

// Add animations
const style = document.createElement('style');
style.textContent = `
  @keyframes slideIn {
    from {
      transform: translateX(400px);
      opacity: 0;
    }
    to {
      transform: translateX(0);
      opacity: 1;
    }
  }

  @keyframes slideOut {
    from {
      transform: translateX(0);
      opacity: 1;
    }
    to {
      transform: translateX(400px);
      opacity: 0;
    }
  }
`;
document.head.appendChild(style);