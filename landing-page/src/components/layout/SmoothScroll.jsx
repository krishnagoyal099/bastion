import Lenis from 'lenis';
import { gsap } from 'gsap';
import { useEffect, useRef } from 'react';

const SmoothScroll = ({ children }) => {
  const lenisRef = useRef();
  
  useEffect(() => {
    const lenis = new Lenis({
      duration: 1.5,
      easing: (t) => Math.min(1, 1.001 - Math.pow(2, -10 * t)),
      orientation: 'vertical',
      gestureOrientation: 'vertical',
      smoothWheel: true,
      touchMultiplier: 2,
    });
    
    lenisRef.current = lenis;

    function update(time) {
      lenis.raf(time * 1000);
    }
  
    gsap.ticker.add(update);
  
    return () => {
      gsap.ticker.remove(update);
      lenis.destroy();
    };
  }, []);

  return (
    <div className="smooth-scroll-wrapper">
      {children}
    </div>
  );
};

export default SmoothScroll;
