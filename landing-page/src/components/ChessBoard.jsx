import React, { useMemo } from 'react';
import * as THREE from 'three';

export function ChessBoard({ size = 20, tiles = 8, tileHeight = 0.05, ...props }) {
  const tileSize = size / tiles;
  const offset = (tiles * tileSize) / 2 - tileSize / 2;

  const instances = useMemo(() => {
    const temp = [];
    for (let row = 0; row < tiles; row++) {
      for (let col = 0; col < tiles; col++) {
        if ((row + col) % 2 === 1) {
          const x = (col * tileSize) - offset;
          const z = (row * tileSize) - offset;
          temp.push({ x, z });
        }
      }
    }
    return temp;
  }, [tiles, tileSize, offset]);

  // "Matte glass" finish - frosted glass aesthetic
  const boardMat = new THREE.MeshPhysicalMaterial({
    color: 0x1a1a1a,         // Dark Grey/Black base
    roughness: 0.35,         // Lower = more sheen (frosted glass feel)
    metalness: 0.15,         // Slight metallic reflection
    clearcoat: 0.8,          // Strong glassy surface layer
    clearcoatRoughness: 0.4, // Matte clearcoat (not mirror-like)
    reflectivity: 0.5,       // Subtle reflections
    transparent: true,
    opacity: 0.92,
    envMapIntensity: 0.6,    // Pick up environment reflections
  });
  
  const frameMat = new THREE.MeshPhysicalMaterial({
      color: 0x2a2a2a,
      roughness: 0.3,
      metalness: 0.3,
      clearcoat: 0.6,
      clearcoatRoughness: 0.3,
  });

  return (
    <group {...props}>
      {/* Grey Tiles */}
      {instances.map((data, i) => (
         <mesh key={i} position={[data.x, 0, data.z]} material={boardMat}>
             <boxGeometry args={[tileSize, tileHeight, tileSize]} />
         </mesh>
      ))}

      {/* Frame - Thin */}
      <mesh position={[0, 0, -size/2 - 0.1]} material={frameMat}>
          <boxGeometry args={[size + 0.4, tileHeight * 1.2, 0.2]} />
      </mesh>
      <mesh position={[0, 0, size/2 + 0.1]} material={frameMat}>
          <boxGeometry args={[size + 0.4, tileHeight * 1.2, 0.2]} />
      </mesh>
      <mesh position={[-size/2 - 0.1, 0, 0]} material={frameMat}>
          <boxGeometry args={[0.2, tileHeight * 1.2, size + 0.4]} />
      </mesh>
      <mesh position={[size/2 + 0.1, 0, 0]} material={frameMat}>
          <boxGeometry args={[0.2, tileHeight * 1.2, size + 0.4]} />
      </mesh>
    </group>
  );
}
