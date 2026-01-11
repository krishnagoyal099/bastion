import React, { useRef, useLayoutEffect } from 'react';
import { Canvas, useFrame } from '@react-three/fiber';
import { Environment, ContactShadows } from '@react-three/drei';
import { ProceduralRook } from './ProceduralRook';
import { ChessBoard } from './ChessBoard';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

// --- CONFIGURATION CONTROLS ---
const BOARD_FINAL_Y = -2.5;  // Decrease to move DOWN, Increase to move UP
const BOARD_SLANT_X = 0.1;  // -0.1 is flat, -0.5 is steep tilt away
// ------------------------------

function Experience() {
  const rookRef = useRef();
  const boardRef = useRef();
  
  useLayoutEffect(() => {
    if (!rookRef.current) return;
    const rook = rookRef.current;
    
    // Initial hidden state for board
    if(boardRef.current) {
      gsap.set(boardRef.current.position, { y: -20 }); // Hide
    }

    const ctx = gsap.context(() => {
      const tl = gsap.timeline({
        scrollTrigger: {
          trigger: "#root",
          start: "top top",
          end: "bottom bottom",
          scrub: 1.2,
        }
      });

      // --- 1. DROP ---
      tl.fromTo(rook.position, 
        { y: 7, x: -1, z: 0 }, 
        { y: 1, x: 2, z: 2, ease: "power1.inOut", duration: 3 }
      );
      tl.fromTo(rook.rotation,
        { x: 0.5, y: 0, z: 0.2 },
        { x: 2, y: 2, z: 1, ease: "none", duration: 3 },
        "<"
      );

      // --- 2. TUMBLE (Alignment) ---
      tl.to(rook.position, {
        y: -1.0, 
        x: -2,
        z: 1,
        ease: "power1.inOut",
        duration: 4
      });
      tl.to(rook.rotation, {
        x: 5.0, 
        y: 5.5,
        z: 0.5, 
        ease: "none",
        duration: 4
      }, "<");

      // --- 3. LANDING (Precision) ---
      // User request: "Rook a bit more up, Board a bit more down".
      // Board must sit "around the rook's foot" (Contact).
      // Rook Center Y = -0.6. Scale 0.55 -> Extent ~1.1. Bottom ~ -1.7.
      // Board Surface Y = -1.7. Center Y = -1.725 (Thickness 0.05).
      
      tl.to(rook.position, {
        y: -0.6, // Higher Center
        x: 0,
        z: 3.5, 
        ease: "elastic.out(0.6, 0.4)",
        duration: 3
      });
      
      tl.to(rook.rotation, {
        x: 6.28 + 0.1, 
        y: 6.28 + 0.2, 
        z: 0,
        ease: "power2.out",
        duration: 3
      }, "<");

      // Board Arrival
      if(boardRef.current) {
        tl.to(boardRef.current.position, {
          y: BOARD_FINAL_Y,
          duration: 2,
          ease: "power2.out"
        }, "-=2");
      }

    });
    return () => ctx.revert();
  }, []);

  // Idle hover
  useFrame((state) => {
     // passive animation
  });

  return (
    <>
      <ambientLight intensity={0.5} />
      <pointLight position={[10, 10, 10]} intensity={2.0} color="#fff" />
      <spotLight position={[0, 10, 0]} intensity={3} penumbra={1} />
      
      <Environment preset="studio" />
      
      <group ref={rookRef}>
        <ProceduralRook />
      </group>
      
      {/* Chess Board - Controls applied here */}
      <group position={[0, -10, 0]} rotation={[BOARD_SLANT_X, 0, 0]} ref={boardRef}>
         <ChessBoard size={30} tiles={8} tileHeight={0.05} />
      </group>
      
      <ContactShadows position={[0, -2.5, 0]} opacity={0.6} scale={10} blur={2} far={4} color="#000" />
    </>
  );
}

export default function RookScene() {
  return (
    <div className="canvas-container">
      <Canvas 
        shadows
        gl={{ antialias: true, toneMappingExposure: 1.0 }}
        camera={{ position: [0, 0, 10], fov: 40 }}
      >
        <Experience />
      </Canvas>
    </div>
  );
}
