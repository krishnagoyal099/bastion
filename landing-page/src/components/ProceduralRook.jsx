import React, { useMemo } from 'react';
import * as THREE from 'three';

// Chrome Matte with slight shine - as requested
const ChromeMatteMaterial = new THREE.MeshPhysicalMaterial({
  color: 0xd0d0d0,          // Light silver/chrome
  metalness: 0.95,
  roughness: 0.35,          // Matte but not fully
  clearcoat: 0.4,           // Slight shine
  clearcoatRoughness: 0.3,
  reflectivity: 0.8,
  envMapIntensity: 1.2,
});

// Polished Chrome for accent rings
const ChromeShinyMaterial = new THREE.MeshPhysicalMaterial({
  color: 0xe8e8e8,
  metalness: 1.0,
  roughness: 0.05,          // Very shiny
  clearcoat: 1.0,
  clearcoatRoughness: 0.02,
  reflectivity: 1.0,
  envMapIntensity: 1.5,
});

// Create a curved slab geometry (arc with thickness)
function createCurvedSlabGeometry(innerRadius, outerRadius, height, startAngle, arcLength, segments = 16) {
  const shape = new THREE.Shape();
  
  // Draw the arc cross-section (a ring segment in 2D)
  // Outer arc
  shape.absarc(0, 0, outerRadius, startAngle, startAngle + arcLength, false);
  // Line to inner arc
  shape.absarc(0, 0, innerRadius, startAngle + arcLength, startAngle, true);
  shape.closePath();
  
  // Extrude it to give height
  const extrudeSettings = {
    depth: height,
    bevelEnabled: false,
  };
  
  return new THREE.ExtrudeGeometry(shape, extrudeSettings);
}

export function ProceduralRook(props) {
  // Create 6 curved slab battlements
  const battlementGeometries = useMemo(() => {
    const count = 6;
    const arcLength = 0.7;    // Arc span of each battlement (radians)
    const gap = (Math.PI * 2 / count) - arcLength;
    
    const innerRadius = 1.05;  // Inner edge of the slab
    const outerRadius = 1.30;  // Outer edge (thickness = 0.25)
    const height = 0.65;       // How tall the battlement is
    
    const geometries = [];
    for (let i = 0; i < count; i++) {
      const startAngle = i * (Math.PI * 2 / count) + gap / 2;
      const geo = createCurvedSlabGeometry(innerRadius, outerRadius, height, startAngle, arcLength);
      geometries.push(geo);
    }
    return geometries;
  }, []);

  return (
    <group {...props}>
      
      {/* ========== BASE ========== */}
      {/* Bottom chrome ring (shiny accent) */}
      <mesh position={[0, -2.3, 0]} material={ChromeShinyMaterial}>
        <cylinderGeometry args={[1.7, 1.8, 0.2, 64]} />
      </mesh>
      
      {/* Base platform */}
      <mesh position={[0, -2.0, 0]} material={ChromeMatteMaterial}>
        <cylinderGeometry args={[1.55, 1.7, 0.4, 64]} />
      </mesh>
      
      {/* Base step */}
      <mesh position={[0, -1.65, 0]} material={ChromeMatteMaterial}>
        <cylinderGeometry args={[1.35, 1.55, 0.3, 64]} />
      </mesh>
      
      {/* ========== BODY ========== */}
      {/* Main tapered column - concave profile */}
      <mesh position={[0, -0.3, 0]} material={ChromeMatteMaterial}>
        <cylinderGeometry args={[0.95, 1.3, 2.4, 64]} />
      </mesh>
      
      {/* ========== COLLAR ========== */}
      {/* Chrome ring at collar (shiny accent) */}
      <mesh position={[0, 1.0, 0]} material={ChromeShinyMaterial}>
        <cylinderGeometry args={[1.1, 0.98, 0.15, 64]} />
      </mesh>
      
      {/* Collar transition */}
      <mesh position={[0, 1.2, 0]} material={ChromeMatteMaterial}>
        <cylinderGeometry args={[1.2, 1.1, 0.25, 64]} />
      </mesh>
      
      {/* ========== HEAD (Turret) ========== */}
      {/* Main turret cylinder */}
      <mesh position={[0, 1.65, 0]} material={ChromeMatteMaterial}>
        <cylinderGeometry args={[1.25, 1.2, 0.65, 64]} />
      </mesh>
      
      {/* ========== CROWN ========== */}
      {/* Crown base ring (shiny accent) */}
      <mesh position={[0, 2.05, 0]} material={ChromeShinyMaterial}>
        <cylinderGeometry args={[1.32, 1.25, 0.12, 64]} />
      </mesh>
      
      {/* Crown inner floor (recessed center) */}
      <mesh position={[0, 2.15, 0]} material={ChromeMatteMaterial}>
        <cylinderGeometry args={[0.85, 0.85, 0.08, 32]} />
      </mesh>
      
      {/* ========== BATTLEMENTS - THICK CURVED SLABS ========== */}
      
      {/* Battlements positioning container */}
      <group position={[0, 2.12, 0]}>
        {battlementGeometries.map((geo, i) => (
          <mesh 
            key={`bat-${i}`} 
            geometry={geo}
            rotation={[-Math.PI / 2, 0, 0]}
            material={ChromeMatteMaterial}
          />
        ))}
      </group>
      
    </group>
  );
}
