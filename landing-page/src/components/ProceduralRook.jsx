import React, { useMemo } from 'react';
import * as THREE from 'three';

const RookMaterial = new THREE.MeshPhysicalMaterial({
  color: 0xeeeeee, 
  metalness: 1.0,
  roughness: 0.2, // Slightly rougher for realism
  clearcoat: 1.0,
  clearcoatRoughness: 0.1,
  reflectivity: 1.0,
});

export function ProceduralRook(props) {
  // Stanton Style Refined: Solid Ring Base + Raised Teeth.
  
  const crownTeeth = useMemo(() => {
    // 4 Distinct blocks
    const segments = [];
    const count = 4;
    const gap = 0.4; // Gap between teeth
    const sector = (Math.PI * 2) / count;
    
    for(let i=0; i<count; i++) {
        const start = i * sector + gap/2;
        const length = sector - gap;
        segments.push({ start, length });
    }
    return segments;
  }, []);

  return (
    <group {...props} scale={0.55}>
      {/* --- BASE --- */}
      <mesh position={[0, -2, 0]} material={RookMaterial}>
        <cylinderGeometry args={[1.6, 1.8, 0.4, 128]} />
      </mesh>
      <mesh position={[0, -1.6, 0]} material={RookMaterial}>
        <cylinderGeometry args={[1.3, 1.6, 0.4, 128]} />
      </mesh>
      
      {/* --- BODY --- */}
      {/* Tapered Concave Body */}
      <mesh position={[0, 0, 0]} material={RookMaterial}>
         {/* Top Radius 1.0, Bottom 1.3 */}
        <cylinderGeometry args={[1.0, 1.3, 3.2, 128]} />
      </mesh>

      {/* --- COLLAR --- */}
      <mesh position={[0, 1.7, 0]} material={RookMaterial}>
        <cylinderGeometry args={[1.4, 1.1, 0.2, 128]} />
      </mesh>
      
      {/* --- HEAD (Turret) --- */}
      {/* The main solid block of the head */}
      <mesh position={[0, 2.1, 0]} material={RookMaterial}>
        <cylinderGeometry args={[1.4, 1.4, 0.6, 128]} />
      </mesh>
      
      {/* --- THE CROWN --- */}
      {/* 1. The Floor (Recessed) */}
      <mesh position={[0, 2.41, 0]} material={RookMaterial}>
         <cylinderGeometry args={[1.2, 1.2, 0.05, 64]} />
      </mesh>
      
      {/* 2. The Teeth (Rising from the rim) */}
      {crownTeeth.map((seg, i) => (
         <mesh 
            key={i} 
            // Positioned ON TOP of the Head (2.1 + 0.3 = 2.4). 
            // Tooth height 0.4 -> center at 2.4 + 0.2 = 2.6
            position={[0, 2.6, 0]} 
            material={RookMaterial}
         >
            {/* Inner Radius 1.0 (Hole), Outer 1.4. This creates the thick wall */}
            <cylinderGeometry 
                args={[1.4, 1.4, 0.45, 64, 1, false, seg.start, seg.length]} 
            />
         </mesh>
      ))}

      {/* Inner Wall helper (to close the gap if cylinderGeometry is single sided?) 
          Three.js cylinder sectors are closed by default? No, 'openEnded' is false. 
          But the "side" faces created by sector cuts are radial planes.
          The "inner" face (radiusTop) needs to come from a separate geometry if we want a ring?
          No, CylinderGeometry with openEnded=false creates caps. 
          But for a RING, we need a tube.
          Let's use a RingGeometry extruded via shape? No, simpler:
          We just render the teeth as solid sectors. 
          But we need the "Hole" to be empty in the middle.
          Standard CylinderGeometry makes a pie slice, not a ring segment.
          
          Ah! Three.js CylinderGeometry creates a solid *slice*. 
          It fills the center to 0,0.
          We need a TUBE segment.
          Solution: Use a `RingGeometry` extruded? Or simpler: Use a subtractive CSG? No, too heavy.
          Visual Hack: Render an "Inner Core" cylinder that is BLACK to simulate depth? 
          Or use `useMemo` with `ExtrudeGeometry` of a predefined Shape (Arc).
          
          Let's try the ExtrudeGeometry approach for the teeth to be perfect.
      */}
      <CrownTeeth segments={crownTeeth} />
      
    </group>
  );
}

// Sub-component for custom extruded arc teeth (Real Pie Sectors)
function CrownTeeth({ segments }) {
  const geometry = useMemo(() => {
    // Create a shape for the pie sector (Wedges)
    // Outer Radius 1.4 (Matches head). 
    // Inner Radius ~0 (Touches center).
    const shapes = [];
    
    segments.forEach((seg) => {
       const shape = new THREE.Shape();
       const rOuter = 1.4;
       
       // Draw Pie Slice
       shape.moveTo(0, 0); // Start at center
       shape.absarc(0, 0, rOuter, seg.start, seg.start + seg.length, false); // Draw Outer Arc
       shape.lineTo(0, 0); // Return to center
       
       shapes.push(shape);
    });
    
    return shapes;
  }, [segments]);

  return (
    <group position={[0, 2.4, 0]} rotation={[Math.PI/2, 0, 0]}> 
       {/* 2.4 Base. Extrude Z (which is Y in world) */}
       {geometry.map((shape, i) => (
         <mesh key={i} material={RookMaterial} rotation={[0, 0, 0]}>
            <extrudeGeometry 
              args={[
                shape, 
                { 
                  depth: 0.50, // Height of the teeth
                  bevelEnabled: true, 
                  bevelThickness: 0.03, 
                  bevelSize: 0.03, 
                  bevelSegments: 4, 
                  curveSegments: 64 
                }
              ]} 
            />
         </mesh>
       ))}
    </group>
  );
}
