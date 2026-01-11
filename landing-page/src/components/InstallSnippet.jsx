import React, { useState } from 'react';
import './InstallSnippet.css';

const copyToClipboard = (text) => {
  navigator.clipboard.writeText(text);
};

const InstallSnippet = () => {
  const [activeTab, setActiveTab] = useState('linux');
  const [copied, setCopied] = useState(false);

  const commands = {
    linux: 'curl -fsSL https://bastion.sh/install.sh | bash',
    macos: 'curl -fsSL https://bastion.sh/install.sh | bash',
    windows: 'wsl --install # Then run Linux command'
  };

  const handleCopy = () => {
    copyToClipboard(commands[activeTab]);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <div className="install-snippet">
      <div className="snippet-header">
        <div className="tabs">
          {['linux', 'macos', 'windows'].map(os => (
            <button 
              key={os}
              className={`tab ${activeTab === os ? 'active' : ''}`}
              onClick={() => setActiveTab(os)}
            >
              {os.charAt(0).toUpperCase() + os.slice(1)}
            </button>
          ))}
        </div>
      </div>
      <div className="snippet-body" onClick={handleCopy}>
        <code className="command">
          <span className="prompt">$</span> {commands[activeTab]}
        </code>
        <button className="copy-btn">
          {copied ? 'Copied' : 'Copy'}
        </button>
      </div>
    </div>
  );
};

export default InstallSnippet;
