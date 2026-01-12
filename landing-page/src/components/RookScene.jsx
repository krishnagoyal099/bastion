import React, { useRef, useLayoutEffect, createContext, useContext } from 'react';
import { Canvas, useThree } from '@react-three/fiber';
import { Environment } from '@react-three/drei';
import { ProceduralRook } from './ProceduralRook';
import { ChessBoard } from './ChessBoard';
import gsap from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

// ============================================================
//   CONFIGURATION - Edit these values to customize the scene
// ============================================================

const CONFIG = {
  
  // --- CAMERA ---
  camera: {
    position: [0, 0, 5],      // Centered, closer for intimate view
    fov: 45,                  // Wider for dramatic perspective
  },

  // --- ROOK ---
  rook: {
    scale: 0.25,              // Visible but not overwhelming
    
    // Starting position - Visible in frame immediately
    startPosition: {
      x: 1.2,                 // Right side
      y: 2.8,                 // LOWER - visible in frame immediately
      z: 0.3,                 // Slightly forward
    },
    
    // Starting rotation - HEAVILY TILTED sideways
    startRotation: {
      x: -0.5,                // Tilted back
      y: 0,                   // Facing forward
      z: 1.2,                 // HEAVILY leaning sideways
    },
    
    // Final resting position
    finalYOffset: 0.65,        // Sitting on board
  },

  // --- CHESSBOARD ---
  board: {
    size: 8,                  // Compact elegant board
    tiles: 8,
    tileHeight: 0.03,
    
    rotation: {
      x: 0.0001,                // Slight tilt toward viewer
      y: 0,
      z: 0,
    },
    
    yOffset: -2,            // At bottom of viewport
    startYOffset: -2,         // Hidden below initially
  },

  // --- ANIMATION PHASES ---
  // Total timeline = 44 units (phases add up to full scroll)
  
  animation: {
    scrubSpeed: 1.5,          // Higher = smoother, no snapping
  },

  // --- LIGHTING ---
  lighting: {
    ambient: 0.3,
    keyLight: { position: [3, 8, 5], intensity: 2.5 },
    rimLight: { position: [-4, 4, -4], intensity: 1.2 },
    fillLight: { position: [0, 0, 6], intensity: 0.6 },
  },

  environment: "city",
};

// ============================================================
//   ROOK ONLY EXPERIENCE (for separate layer)
// ============================================================

function RookExperience() {
  const rookRef = useRef();
  const { viewport } = useThree();
  
  useLayoutEffect(() => {
    if (!rookRef.current) return;
    const rook = rookRef.current;

    // Calculate final positions
    const fovRad = (CONFIG.camera.fov * Math.PI) / 180;
    const cameraZ = CONFIG.camera.position[2];
    const visibleHeight = 2 * cameraZ * Math.tan(fovRad / 2);
    const visibleBottom = -visibleHeight / 2;
    
    const boardFinalY = visibleBottom + CONFIG.board.yOffset + 2.5;
    const rookFinalY = boardFinalY + CONFIG.rook.finalYOffset;
    
    // === INITIAL STATES ===
    gsap.set(rook.position, CONFIG.rook.startPosition);
    gsap.set(rook.rotation, CONFIG.rook.startRotation);

    const ctx = gsap.context(() => {
      const tl = gsap.timeline({
        scrollTrigger: {
          trigger: "#root",
          start: "top top",
          end: "bottom bottom",
          scrub: true,
        }
      });

      // --- Phase 1: Top right → curving LEFT (0 → 12) ---
      tl.to(rook.position, {
        y: 1.8,
        x: -0.8,
        z: 0,
        duration: 12,
        ease: "none",
      }, 0);
      
      tl.to(rook.rotation, {
        y: Math.PI * 0.5,
        x: -0.2,
        z: 0.7,
        duration: 12,
        ease: "none",
      }, 0);

      // --- Phase 2: LEFT → curving back RIGHT (12 → 28) ---
      tl.to(rook.position, {
        y: 0.4,
        x: 0.9,
        z: 0,
        duration: 16,
        ease: "none",
      }, 12);
      
      tl.to(rook.rotation, {
        y: Math.PI * 1.2,
        x: 0.1,
        z: -0.4,
        duration: 16,
        ease: "none",
      }, 12);

      // --- Phase 3a: RIGHT → CENTER approach (28 → 36) ---
      tl.to(rook.position, {
        y: rookFinalY + 0.5,
        x: 0.3,
        z: 0,
        duration: 8,
        ease: "none",
      }, 28);
      
      tl.to(rook.rotation, {
        y: Math.PI * 1.6,
        x: 0,
        z: -0.1,
        duration: 8,
        ease: "none",
      }, 28);

      // --- Phase 3b: CENTER approach → final position (36 → 44) ---
      tl.to(rook.position, {
        y: rookFinalY + 0.25,
        x: 0,
        z: 0,
        duration: 8,
        ease: "none",
      }, 36);
      
      tl.to(rook.rotation, {
        y: Math.PI * 1.9,
        x: 0,
        z: 0,
        duration: 8,
        ease: "none",
      }, 36);

      // --- Phase 4: LANDING (44 → 50) ---
      tl.to(rook.position, {
        y: rookFinalY,
        duration: 6,
        ease: "none",
      }, 44);
      
      tl.to(rook.rotation, {
        y: Math.PI * 2,
        duration: 6,
        ease: "none",
      }, 44);

    });

    return () => ctx.revert();
  }, [viewport]);

  return (
    <>
      <ambientLight intensity={CONFIG.lighting.ambient} />
      <directionalLight 
        position={CONFIG.lighting.keyLight.position} 
        intensity={CONFIG.lighting.keyLight.intensity} 
        color="#ffffff"
        castShadow
      />
      <pointLight 
        position={CONFIG.lighting.rimLight.position} 
        intensity={CONFIG.lighting.rimLight.intensity} 
        color="#e8e8e8"
      />
      <pointLight 
        position={CONFIG.lighting.fillLight.position} 
        intensity={CONFIG.lighting.fillLight.intensity} 
        color="#d0d0d0"
      />
      <Environment preset={CONFIG.environment} />
      
      <group ref={rookRef}>
        <ProceduralRook scale={CONFIG.rook.scale} />
      </group>
    </>
  );
}

// ============================================================
//   BOARD ONLY EXPERIENCE (for separate layer)
// ============================================================

function BoardExperience() {
  const boardRef = useRef();
  const { viewport } = useThree();
  
  useLayoutEffect(() => {
    if (!boardRef.current) return;
    const board = boardRef.current;

    const fovRad = (CONFIG.camera.fov * Math.PI) / 180;
    const cameraZ = CONFIG.camera.position[2];
    const visibleHeight = 2 * cameraZ * Math.tan(fovRad / 2);
    const visibleBottom = -visibleHeight / 2;
    
    const boardFinalY = visibleBottom + CONFIG.board.yOffset + 2.5;
    
    // Board: Hidden below initially
    gsap.set(board.position, { 
      x: 0,
      y: boardFinalY + CONFIG.board.startYOffset, 
      z: 0 
    });
    gsap.set(board.scale, { x: 0.8, y: 0.8, z: 0.8 });

    const ctx = gsap.context(() => {
      const tl = gsap.timeline({
        scrollTrigger: {
          trigger: "#root",
          start: "top top",
          end: "bottom bottom",
          scrub: true,
        }
      });

      // --- BOARD EMERGES (28 → 40) ---
      tl.to(board.position, {
        y: boardFinalY,
        duration: 12,
        ease: "none",
      }, 28);
      
      tl.to(board.scale, {
        x: 1, y: 1, z: 1,
        duration: 12,
        ease: "none",
      }, 28);

    });

    return () => ctx.revert();
  }, [viewport]);

  return (
    <>
      <ambientLight intensity={CONFIG.lighting.ambient} />
      <directionalLight 
        position={CONFIG.lighting.keyLight.position} 
        intensity={CONFIG.lighting.keyLight.intensity} 
        color="#ffffff"
        castShadow
      />
      <pointLight 
        position={CONFIG.lighting.rimLight.position} 
        intensity={CONFIG.lighting.rimLight.intensity} 
        color="#e8e8e8"
      />
      <Environment preset={CONFIG.environment} />
      
      <group 
        ref={boardRef} 
        rotation={[
          CONFIG.board.rotation.x, 
          CONFIG.board.rotation.y, 
          CONFIG.board.rotation.z
        ]}
      >
        <ChessBoard 
          size={CONFIG.board.size} 
          tiles={CONFIG.board.tiles} 
          tileHeight={CONFIG.board.tileHeight} 
        />
      </group>
    </>
  );
}

// ============================================================
//   SEPARATE CANVAS COMPONENTS FOR Z-INDEX CONTROL
// ============================================================

// Chessboard layer - will be at lower z-index (behind text)
export function ChessBoardScene() {
  return (
    <div className="canvas-container">
      <Canvas 
        shadows
        gl={{ 
          antialias: true, 
          toneMappingExposure: 1.4,
          toneMapping: 3
        }}
        camera={{ 
          position: CONFIG.camera.position, 
          fov: CONFIG.camera.fov,
          near: 0.1,
          far: 100
        }}
      >
        <BoardExperience />
      </Canvas>
    </div>
  );
}

// Rook layer - will be at higher z-index (above text)
export function RookOnlyScene() {
  return (
    <div className="canvas-container">
      <Canvas 
        shadows
        gl={{ 
          antialias: true, 
          alpha: true,  // Transparent background
          toneMappingExposure: 1.4,
          toneMapping: 3
        }}
        camera={{ 
          position: CONFIG.camera.position, 
          fov: CONFIG.camera.fov,
          near: 0.1,
          far: 100
        }}
      >
        <RookExperience />
      </Canvas>
    </div>
  );
}

// ============================================================
//   LEGACY DEFAULT EXPORT (combined scene)
// ============================================================

function Experience() {
  const rookRef = useRef();
  const boardRef = useRef();
  const { viewport } = useThree();
  
  useLayoutEffect(() => {
    if (!rookRef.current || !boardRef.current) return;
    const rook = rookRef.current;
    const board = boardRef.current;

    // Calculate final positions
    const fovRad = (CONFIG.camera.fov * Math.PI) / 180;
    const cameraZ = CONFIG.camera.position[2];
    const visibleHeight = 2 * cameraZ * Math.tan(fovRad / 2);
    const visibleBottom = -visibleHeight / 2;
    
    const boardFinalY = visibleBottom + CONFIG.board.yOffset + 2.5;
    const rookFinalY = boardFinalY + CONFIG.rook.finalYOffset;
    
    // === INITIAL STATES ===
    // Rook: Top of screen, slanted, ready to fall
    gsap.set(rook.position, CONFIG.rook.startPosition);
    gsap.set(rook.rotation, CONFIG.rook.startRotation);
    
    // Board: Hidden below
    gsap.set(board.position, { 
      x: 0,
      y: boardFinalY + CONFIG.board.startYOffset, 
      z: 0 
    });
    gsap.set(board.scale, { x: 0.8, y: 0.8, z: 0.8 }); // Start slightly smaller

    const ctx = gsap.context(() => {
      // Use scrub: true for frame-perfect, no-interpolation scrolling
      // This eliminates the "snapping" that happens with numeric scrub values
      const tl = gsap.timeline({
        scrollTrigger: {
          trigger: "#root",
          start: "top top",
          end: "bottom bottom",
          scrub: true, // Frame-perfect scrubbing - no catchup delay
        }
      });

      // ========================================================
      // 🎬 CONTINUOUS S-CURVE PATH - Granular keyframes to prevent snapping
      // Using "none" (linear) easing at phase boundaries for seamless transitions
      // ========================================================
      
      // --- Phase 1: Top right → curving LEFT (0 → 12) ---
      tl.to(rook.position, {
        y: 1.8,
        x: -0.8,
        z: 0,
        duration: 12,
        ease: "none",   // Linear - no acceleration discontinuity
      }, 0);
      
      tl.to(rook.rotation, {
        y: Math.PI * 0.5,
        x: -0.2,
        z: 0.7,
        duration: 12,
        ease: "none",
      }, 0);

      // --- Phase 2: LEFT → curving back RIGHT (12 → 28) ---
      tl.to(rook.position, {
        y: 0.4,
        x: 0.9,
        z: 0,
        duration: 16,
        ease: "none",   // Linear - smooth continuous motion
      }, 12);
      
      tl.to(rook.rotation, {
        y: Math.PI * 1.2,
        x: 0.1,
        z: -0.4,
        duration: 16,
        ease: "none",
      }, 12);

      // --- Phase 3a: RIGHT → CENTER approach (28 → 36) ---
      // Split into two sub-phases for more granular control
      tl.to(rook.position, {
        y: rookFinalY + 0.5, // Intermediate position above final
        x: 0.3,              // Moving toward center
        z: 0,
        duration: 8,
        ease: "none",
      }, 28);
      
      tl.to(rook.rotation, {
        y: Math.PI * 1.6,
        x: 0,
        z: -0.1,             // Almost upright
        duration: 8,
        ease: "none",
      }, 28);

      // --- BOARD EMERGES (28 → 40) - starts SAME time as Phase 3a ---
      // Continuous motion with the rook approach
      tl.to(board.position, {
        y: boardFinalY,
        duration: 12,
        ease: "none",        // Linear - no snapping
      }, 28);
      
      tl.to(board.scale, {
        x: 1, y: 1, z: 1,
        duration: 12,
        ease: "none",
      }, 28);

      // --- Phase 3b: CENTER approach → final position (36 → 44) ---
      tl.to(rook.position, {
        y: rookFinalY + 0.25,
        x: 0,
        z: 0,
        duration: 8,
        ease: "none",
      }, 36);
      
      tl.to(rook.rotation, {
        y: Math.PI * 1.9,
        x: 0,
        z: 0,
        duration: 8,
        ease: "none",
      }, 36);

      // --- Phase 4: LANDING (44 → 50) ---
      tl.to(rook.position, {
        y: rookFinalY,
        duration: 6,
        ease: "none",
      }, 44);
      
      tl.to(rook.rotation, {
        y: Math.PI * 2,
        duration: 6,
        ease: "none",
      }, 44);

    });

    return () => ctx.revert();
  }, [viewport]);

  return (
    <>
      {/* === CINEMATIC LIGHTING === */}
      <ambientLight intensity={CONFIG.lighting.ambient} />
      
      {/* Key Light - dramatic top-right */}
      <directionalLight 
        position={CONFIG.lighting.keyLight.position} 
        intensity={CONFIG.lighting.keyLight.intensity} 
        color="#ffffff"
        castShadow
      />
      
      {/* Rim Light - silhouette definition */}
      <pointLight 
        position={CONFIG.lighting.rimLight.position} 
        intensity={CONFIG.lighting.rimLight.intensity} 
        color="#e8e8e8"
      />
      
      {/* Fill Light - front subtle */}
      <pointLight 
        position={CONFIG.lighting.fillLight.position} 
        intensity={CONFIG.lighting.fillLight.intensity} 
        color="#d0d0d0"
      />
      
      <Environment preset={CONFIG.environment} />
      
      {/* === THE ROOK === */}
      <group ref={rookRef}>
        <ProceduralRook scale={CONFIG.rook.scale} />
      </group>
      
      {/* === THE BOARD === */}
      <group 
        ref={boardRef} 
        rotation={[
          CONFIG.board.rotation.x, 
          CONFIG.board.rotation.y, 
          CONFIG.board.rotation.z
        ]}
      >
        <ChessBoard 
          size={CONFIG.board.size} 
          tiles={CONFIG.board.tiles} 
          tileHeight={CONFIG.board.tileHeight} 
        />
      </group>
    </>
  );
}

export default function RookScene() {
  return (
    <div className="canvas-container">
      <Canvas 
        shadows
        gl={{ 
          antialias: true, 
          toneMappingExposure: 1.4,
          toneMapping: 3  // ACES Filmic for cinema
        }}
        camera={{ 
          position: CONFIG.camera.position, 
          fov: CONFIG.camera.fov,
          near: 0.1,
          far: 100
        }}
      >
        <Experience />
      </Canvas>
    </div>
  );
}

