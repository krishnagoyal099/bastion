import React from 'react';

const visualStyle = {
  width: '100%',
  height: '100%',
  display: 'flex',
  justifyContent: 'center',
  alignItems: 'center',
  background: 'rgba(255,255,255,0.03)',
  border: '1px solid rgba(255,255,255,0.1)',
};

export const DarkOrdersVisual = () => (
  <div style={visualStyle}>
    <svg width="200" height="150" viewBox="0 0 200 150" fill="none" stroke="white" strokeWidth="2">
      {/* Hidden Block */}
      <rect x="50" y="40" width="100" height="60" fill="rgba(255,255,255,0.05)" strokeDasharray="5 5" />
      <text x="100" y="75" textAnchor="middle" fill="white" fontSize="12" fontFamily="Helvetica">HIDDEN</text>
      
      {/* Input Lines */}
      <path d="M 20 70 L 50 70" markerEnd="url(#arrow)" />
      <path d="M 150 70 L 180 70" markerEnd="url(#arrow)" />
    </svg>
  </div>
);

export const ZKVisual = () => (
  <div style={visualStyle}>
    <svg width="200" height="150" viewBox="0 0 200 150" fill="none" stroke="white" strokeWidth="2">
      {/* Shield */}
      <path d="M 100 20 C 100 20, 150 30, 150 60 C 150 100, 100 130, 100 130 C 100 130, 50 100, 50 60 C 50 30, 100 20, 100 20 Z" />
      {/* Keyhole */}
      <circle cx="100" cy="65" r="8" fill="white" />
      <path d="M 100 65 L 100 85" strokeWidth="4" />
    </svg>
  </div>
);

export const AMMVisual = () => (
  <div style={visualStyle}>
     <svg width="200" height="150" viewBox="0 0 200 150" fill="none" stroke="white" strokeWidth="2">
      {/* Axes */}
      <line x1="20" y1="130" x2="180" y2="130" />
      <line x1="20" y1="130" x2="20" y2="20" />
      
      {/* Curve */}
      <path d="M 30 20 Q 30 120 180 120" stroke="white" fill="none" />
      
      {/* Points */}
      <circle cx="70" cy="85" r="4" fill="white" />
      <circle cx="120" cy="115" r="4" fill="white" />
    </svg>
  </div>
);
