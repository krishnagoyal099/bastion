import { useEffect, useRef, useState } from 'react';
import { gsap } from 'gsap';

const CustomCursor = () => {
  const cursorRef = useRef(null);
  const pos = useRef({ x: 0, y: 0 });
  const [isVisible, setIsVisible] = useState(false);

  useEffect(() => {
    const cursor = cursorRef.current;
    
    // Smooth follow using GSAP
    const xTo = gsap.quickTo(cursor, "x", { duration: 0.2, ease: "power3.out" });
    const yTo = gsap.quickTo(cursor, "y", { duration: 0.2, ease: "power3.out" });
    
    const onMouseMove = (e) => {
      if (!isVisible) setIsVisible(true);
      xTo(e.clientX);
      yTo(e.clientY);
      
      // Hover detection
      const target = e.target;
      const isHoverable = target.closest('a') || target.closest('button') || target.closest('.hover-trigger');
      
      if (isHoverable) {
        gsap.to(cursor, { scale: 3, duration: 0.3, ease: "power2.out" });
      } else {
        gsap.to(cursor, { scale: 1, duration: 0.3, ease: "power2.out" });
      }
    };

    const onMouseLeave = () => setIsVisible(false);
    const onMouseEnter = () => setIsVisible(true);

    window.addEventListener('mousemove', onMouseMove);
    document.body.addEventListener('mouseleave', onMouseLeave);
    document.body.addEventListener('mouseenter', onMouseEnter);
    
    return () => {
      window.removeEventListener('mousemove', onMouseMove);
      document.body.removeEventListener('mouseleave', onMouseLeave);
      document.body.removeEventListener('mouseenter', onMouseEnter);
    };
  }, [isVisible]);

  return (
    <div 
      ref={cursorRef} 
      className={`fixed top-0 left-0 w-4 h-4 bg-swiss-accent rounded-full pointer-events-none z-[9999] mix-blend-difference ${isVisible ? 'opacity-100' : 'opacity-0'}`}
      style={{ 
        transform: 'translate(-50%, -50%)',
        willChange: 'transform'
      }}
    />
  );
};

export default CustomCursor;

