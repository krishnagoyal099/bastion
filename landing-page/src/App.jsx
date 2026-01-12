import React, { useEffect, useRef } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import RookScene from './components/RookScene';
import InstallSnippet from './components/InstallSnippet';
// ImagePlaceholder for feature sections
const ImagePlaceholder = ({ label }) => (
  <div className="w-full aspect-video bg-gradient-to-br from-swiss-black to-neutral-900 border border-swiss-white/10 rounded-lg flex items-center justify-center">
    <span className="text-neutral-600 text-sm font-mono">[{label}]</span>
  </div>
);
import CustomCursor from './components/ui/CustomCursor';
import NoiseOverlay from './components/ui/NoiseOverlay';
import SmoothScroll from './components/layout/SmoothScroll';
import Marquee from './components/ui/Marquee';

gsap.registerPlugin(ScrollTrigger);

function App() {
  const heroTextRef = useRef(null);
  const heroSubRef = useRef(null);
  const featureRef = useRef(null);

  useEffect(() => {
    // Hero Text Stagger Reveal
    const chars = heroTextRef.current.querySelectorAll('.char');
    gsap.fromTo(chars, 
      { 
        y: 200, 
        skewY: 10,
        opacity: 0 
      },
      { 
        y: 0, 
        skewY: 0, 
        opacity: 1,
        stagger: 0.05, 
        duration: 1.2, 
        ease: "power4.out",
        delay: 0.2
      }
    );

    gsap.fromTo(heroSubRef.current,
        { opacity: 0, y: 20 },
        { opacity: 1, y: 0, duration: 1, delay: 1, ease: "power2.out" }
    );

    // Parallax for features
    const sections = gsap.utils.toArray('.feature-section');
    sections.forEach((section, i) => {
        gsap.fromTo(section.querySelector('.content-block'), 
            { y: 100, opacity: 0 },
            {
                y: 0,
                opacity: 1,
                scrollTrigger: {
                    trigger: section,
                    start: "top 80%",
                    end: "top 20%",
                    scrub: 1
                }
            }
        );
    });

  }, []);

  return (
    <SmoothScroll>
      <CustomCursor />
      <NoiseOverlay />
      
      {/* Background 3D Scene - Fixed (Layer 3) */}
      <div className="fixed inset-0 z-0 pointer-events-none">
        <RookScene />
      </div>

      {/* Grid Lines - Fixed Background (Layer 4) */}
      <div className="fixed inset-0 z-[-1] w-full h-full pointer-events-none flex justify-between">
            <div className="w-px h-full bg-swiss-white/5 mx-auto"></div>
            <div className="w-px h-full bg-swiss-white/5 absolute left-1/4"></div>
            <div className="w-px h-full bg-swiss-white/5 absolute right-1/4"></div>
      </div>

      <div className="relative z-10 w-full min-h-screen">
        
        {/* Navigation / Header */}
        <header className="fixed top-0 left-0 w-full p-8 flex justify-between items-start mix-blend-difference z-50">
            <div className="text-xs font-bold tracking-widest leading-none">
                BASTION PROTOCOL<br/>
                <br/>
                <span className="text-xs font-bold tracking-widest leading-none text-black bg-swiss-white px-2 py-0.5 rounded-xl">V0.9.4 BETA</span>
            </div>
            <div className="text-right text-xs font-bold tracking-widest leading-none">
                CASPER NETWORK v2
            </div>
        </header>

        {/* HERO SECTION */}
        <section className="relative w-full h-screen flex flex-col justify-center items-center px-4 overflow-hidden">
            {/* Massive Title */}
            <h1 ref={heroTextRef} className="font-swiss text-massive text-swiss-white font-bold uppercase text-center leading-[0.8] tracking-tighter mix-blend-difference select-none">
                <div className="overflow-hidden">
                    {"BASTION".split("").map((char, i) => (
                        <span key={i} className="char inline-block">{char}</span>
                    ))}
                </div>
            </h1>

            {/* Subtext & Install */}
            <div ref={heroSubRef} className="mt-12 flex flex-col items-center gap-8 max-w-xl w-full z-20">
                <p className="font-swiss text-sm font-medium tracking-wide text-center text-swiss-white/60">
                    PRIVACY PRESERVING DARK POOL TRADING INFRASTRUCTURE.<br/>
                    BUILT ON CASPER. POWERED BY ZK-SNARKS.
                </p>
                <InstallSnippet />
            </div>
        </section>

        {/* MARQUEE SEPARATOR */}
        <div className="py-24 pointer-events-none relative z-1">
             <Marquee text="SECURE • PRIVATE • UNSTOPPABLE •" speed={0.5} />
        </div>

        {/* FEATURES - ASYMMETRIC GRID */}
        <div className="relative w-full text-swiss-white">
            
            {/* Feature 01 */}
            <section className="feature-section relative min-h-screen flex items-center px-8 py-24 border-t border-swiss-white/10">
                <div className="content-block w-full max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-16 items-center">
                    <div className="order-2 md:order-1">
                        <ImagePlaceholder label="DARK_TRADE_DEMO.png" />
                    </div>
                    <div className="order-1 md:order-2 md:pl-16">
                         <span className="text-swiss-accent text-xs font-bold tracking-widest mb-4 block">01. DARK LIQUIDITY</span>
                         <h2 className="text-6xl md:text-8xl font-bold tracking-tighter leading-[0.9] mb-8">
                             INVISIBLE<br/>ORDERS.
                         </h2>
                         <p className="text-neutral-400 max-w-md text-lg leading-relaxed">
                             Execute trades without market impact. Orders remain redacted until execution, preventing MEV exploitation and front-running.
                         </p>
                    </div>
                </div>
            </section>

             {/* Feature 02 */}
             <section className="feature-section relative min-h-screen flex items-center px-8 py-24 border-t border-swiss-white/10">
                <div className="content-block w-full max-w-7xl mx-auto grid grid-cols-1 md:grid-cols-2 gap-16 items-center">
                    <div className="md:pr-16">
                         <span className="text-swiss-accent text-xs font-bold tracking-widest mb-4 block">02. ZERO KNOWLEDGE</span>
                         <h2 className="text-6xl md:text-8xl font-bold tracking-tighter leading-[0.9] mb-8">
                             MATH<br/>NOT TRUST.
                         </h2>
                         <p className="text-neutral-400 max-w-md text-lg leading-relaxed">
                             Solvency is guaranteed by ZK-SNARKs on Casper. Prove you have the funds without revealing your balance.
                         </p>
                    </div>
                    <div>
                        <ImagePlaceholder label="ZK_PROOF_DEMO.png" />
                    </div>
                </div>
            </section>

            {/* Feature 03 - Diagonal */}
            <section className="feature-section relative min-h-[80vh] flex items-center justify-center px-8 py-24 overflow-hidden border-t border-swiss-white/10">
                <div className="absolute inset-0 transform -skew-y-3 bg-swiss-white/5 origin-top-left scale-110 pointer-events-none"></div>
                <div className="content-block relative z-10 text-center flex flex-col items-center">
                     <h2 className="text-6xl md:text-9xl font-bold tracking-tighter leading-none mb-4 mix-blend-exclusion">
                         PUBLIC
                         <span className="text-swiss-accent block">AMM</span>
                         LAYER
                     </h2>
                     <p className="text-neutral-500 max-w-xl text-center text-xl mt-8">
                         When dark liquidity is scarce, seamlessly rout orders through the public AMM for instant execution.
                     </p>
                </div>
            </section>

            {/* FINAL SECTION - Clean layout */}
            <section className="relative px-8 py-24 min-h-screen flex flex-col">
                <div className="max-w-7xl mx-auto w-full flex-1 flex flex-col">
                    
                    {/* TAGLINE - at top */}
                    <div className="mb-auto">
                        <h2 className="text-[10vw] leading-[0.85] font-black tracking-tighter uppercase">
                            <span className="block text-swiss-white">Trust The Rook</span>
                            <span className="block text-swiss-accent mt-2 md:pl-24">And The Board Is Yours.</span>
                        </h2>
                    </div>
                    
                    
                    {/* BOTTOM ROW - Just BASTION */}
                    <div className="mt-auto pt-48">
                        <h3 className="text-4xl font-bold tracking-tighter">BASTION.</h3>
                    </div>
                    
                </div>
            </section>

            {/* Footer - Minimal with socials */}
            <footer className="relative border-t border-swiss-white/10 py-8 px-8 z-50 bg-black/50 backdrop-blur-md">
                <div className="max-w-7xl mx-auto flex justify-between items-center">
                    <div className="text-xs text-white font-mono">
                        © 2026 BASTION PROTOCOL. ALL RIGHTS RESERVED.
                    </div>
                    <div className="flex items-center gap-6">
                        <a href="https://x.com/bastioncspr" className="text-xs text-white font-mono hover:text-swiss-accent transition-colors">X (TWITTER)</a>
                        <a href="https://github.com/krishnagoyal099/bastion" className="text-xs text-white font-mono hover:text-swiss-accent transition-colors">GITHUB</a>
                    </div>
                </div>
            </footer>
        </div>
      </div>
    </SmoothScroll>
  );
}

export default App;
