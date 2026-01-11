import React from 'react';
import RookScene from './components/RookScene';
import InstallSnippet from './components/InstallSnippet';
import { TerminalBlock } from './components/TerminalBlock';
import './App.css';

function App() {
  return (
    <>
      <div className="canvas-container">
        <RookScene />
      </div>
      
      {/* Grid Overlay */}
      <div className="grid-overlay">
        {Array.from({ length: 12 }).map((_, i) => (
          <div key={i} className="col"></div>
        ))}
      </div>

      <main className="snap-container">
        {/* Section 1: Hero */}
        <section className="swiss-section hero">
          <div className="content-grid">
            <div className="header-block">
              <h1 className="swiss-title">BASTION</h1>
              <div className="header-right">
                 <a href="https://github.com/krishnagoyal099/bastion" className="github-btn" target="_blank" rel="noreferrer">
                    GITHUB ↗
                 </a>
                 <div className="meta-info">
                   <span className="label">PROTOCOL V0.9.4</span>
                   <span className="label">CASPER NETWORK V2</span>
                 </div>
              </div>
            </div>
            
            <div className="hero-statement">
               <p>PRIVACY PRESERVING<br/>DARK POOL TRADING<br/>INFRASTRUCTURE.</p>
            </div>

            <div className="install-block">
               <InstallSnippet />
            </div>
          </div>
        </section>

        {/* Section 2: Manifesto / Features */}
        <section className="swiss-section manifesto">
           <div className="content-grid two-col">
              {/* Feature 1 */}
              <div className="text-col">
                 <h2>01. DARK LIMIT ORDERS</h2>
                 <p className="description">
                   Orders remain invisible (redacted) until execution. 
                   Prevents MEV exploitation via ZK-SNARKs.
                 </p>
                 <TerminalBlock 
                   command="bastion trade --pair BTC-USDT --side buy --amount 0.5 --limit obscured"
                   outputLines={[
                     "[INFO]  Initiating Dark Handshake...",
                     "[ZK]    Generating proof of solvency...",
                     "[OK]    Proof verified (14ms).",
                     "[NET]   Order 0x7f3a9 submitted to Dark Pool via Gosier Relayer.",
                     "[STAT]  Queued. Market impact: 0.00%."
                   ]}
                 />
              </div>
              
              {/* Feature 2 (Offset) */}
              <div className="text-col offset-down">
                 <h2>02. ZK PROVEN</h2>
                 <p className="description">
                   Mathematical guarantees of solvency without revealing data.
                   Zero-knowledge verification on Casper.
                 </p>
                 <TerminalBlock 
                   command="bastion proof generate --order-id 0x7f3a9"
                   outputLines={[
                     "[CORE]  Loading circuit params (Casper-Groth16)...",
                     "[WIT]   Computing witness...",
                     "[ZK]    Proving...",
                     "[OK]    Proof generated: b64/eyJhIj... [Attached]",
                     "[INFO]  Ready for on-chain verification."
                   ]}
                 />
              </div>
              
               {/* Feature 3 (New) */}
              <div className="text-col">
                 <h2>03. PUBLIC AMM</h2>
                 <p className="description">
                   Hybrid liquidity layer for instant execution when dark pool liquidity is low.
                 </p>
                 <TerminalBlock 
                   command="bastion swap --pair ETH-USDT --amount 10.0"
                   outputLines={[
                     "[ROUT]  Scanning liquidity sources...",
                     "[AMM]   Route found: CSPR -> ETH -> USDT",
                     "[EST]   Price: 2,250.50 USDT/ETH",
                     "[TX]    Submitted to Mainnet (DeployHash: 0x9c2...)",
                     "[CONF]  Swap executed. Balance updated."
                   ]}
                 />
              </div>
           </div>
        </section>

        {/* Section 3: Closing */}
        <section className="swiss-section closing">
           <div className="closing-content">
              <h2 className="final-statement font-bold">TRUST THE ROOK<br/>AND THE BOARD IS YOURS.</h2>
              
              <div className="footer-meta">
                <div className="meta-item">
                  <span>DEPLOYED ON</span>
                  <span>CASPER TESTNET</span>
                </div>
                <div className="meta-item">
                  <span>VERSION</span>
                  <span>v5.7.3-BETA</span>
                </div>
                <a href="https://x.com/bastioncspr" className="github-btn" target="_blank" rel="noreferrer">
                    Open X ↗
                 </a>
              </div>
           </div>
        </section>
      </main>
    </>
  );
}

export default App;
