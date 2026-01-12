import React from 'react';

export function TerminalBlock({ command, outputLines = [] }) {
  return (
    <div className="w-full bg-[#111] border border-swiss-white/10 font-mono text-sm leading-relaxed overflow-hidden">
      {/* Minimal Header */}
      <div className="bg-[#0A0A0A] px-4 py-2 flex items-center gap-2 border-b border-swiss-white/5">
        <div className="w-2 h-2 rounded-full bg-swiss-white/20"></div>
        <div className="w-2 h-2 rounded-full bg-swiss-white/20"></div>
        <div className="ml-auto text-xs text-neutral-600 uppercase tracking-wider">sh</div>
      </div>

      {/* Terminal Body */}
      <div className="p-6 text-swiss-white/80">
        <div className="mb-4 flex gap-2">
            <span className="text-swiss-accent font-bold">➜</span>
            <span className="text-white">{command}</span>
        </div>
        
        <div className="space-y-1 text-neutral-400">
          {outputLines.map((line, i) => (
             <div key={i}>{line}</div>
          ))}
        </div>
        
        {/* Blinking Cursor */}
        <div className="mt-2 flex gap-2">
             <span className="text-swiss-accent font-bold">➜</span>
             <span className="w-2 h-5 bg-swiss-white animate-pulse"></span>
        </div>
      </div>
    </div>
  );
}
