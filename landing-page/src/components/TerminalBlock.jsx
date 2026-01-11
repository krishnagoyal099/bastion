import React from 'react';

export function TerminalBlock({ command, outputLines = [] }) {
  return (
    <div style={{
      width: '100%',
      backgroundColor: '#111', 
      borderRadius: '6px',
      overflow: 'hidden',
      boxShadow: '0 10px 30px rgba(0,0,0,0.5)',
      fontFamily: '"Fira Code", "Courier New", monospace',
      fontSize: '0.85rem',
      lineHeight: '1.5',
      textAlign: 'left',
      border: '1px solid #333'
    }}>
      {/* Window Header */}
      <div style={{
        backgroundColor: '#1f1f1f',
        padding: '8px 12px',
        display: 'flex',
        gap: '6px',
        borderBottom: '1px solid #333'
      }}>
        <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#ff5f56' }}></div>
        <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#ffbd2e' }}></div>
        <div style={{ width: '10px', height: '10px', borderRadius: '50%', background: '#27c93f' }}></div>
        <div style={{ marginLeft: 'auto', color: '#666', fontSize: '0.7rem' }}>bash — 80x24</div>
      </div>

      {/* Terminal Body */}
      <div style={{ padding: '20px', color: '#f0f0f0' }}>
        {/* Prompt line */}
        <div style={{ marginBottom: '10px' }}>
          <span style={{ color: '#27c93f', fontWeight: 'bold' }}>root@bastion</span>
          <span style={{ color: '#fff' }}>:</span>
          <span style={{ color: '#5dadf0', fontWeight: 'bold' }}>~</span>
          <span style={{ color: '#fff' }}>$ </span>
          <span>{command}</span>
        </div>
        
        {/* Output */}
        <div style={{ color: '#ccc' }}>
          {outputLines.map((line, i) => (
             <div key={i}>{line}</div>
          ))}
        </div>
        
        {/* Active Cursor */}
        <div style={{ marginTop: '5px' }}>
             <span style={{ color: '#27c93f', fontWeight: 'bold' }}>root@bastion</span>
            <span style={{ color: '#fff' }}>:</span>
            <span style={{ color: '#5dadf0', fontWeight: 'bold' }}>~</span>
            <span style={{ color: '#fff' }}>$ </span>
            <span style={{ display: 'inline-block', width: '8px', height: '15px', background: '#ccc', verticalAlign: 'middle' }}></span>
        </div>
      </div>
    </div>
  );
}
