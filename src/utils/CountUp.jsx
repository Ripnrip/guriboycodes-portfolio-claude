import React, { useState, useEffect } from 'react'

// Simple hook for intersection observer
function useInViewHook(options) {
  const [isInView, setIsInView] = useState(false)
  const ref = React.useRef(null)

  useEffect(() => {
    const observer = new IntersectionObserver(([entry]) => {
      if (entry.isIntersecting) {
        setIsInView(true)
        if (options.triggerOnce) {
          observer.unobserve(entry.target)
        }
      } else if (!options.triggerOnce) {
        setIsInView(false)
      }
    }, { threshold: options.threshold || 0.1 })

    if (ref.current) {
      observer.observe(ref.current)
    }

    return () => {
      if (ref.current) {
        observer.unobserve(ref.current)
      }
    }
  }, [options])

  return { ref, inView: isInView }
}

const CountUp = ({ end, duration = 2 }) => {
  const [count, setCount] = useState(0)
  const { ref, inView } = useInViewHook({ threshold: 0.5, triggerOnce: true })

  useEffect(() => {
    if (!inView) return

    let start = 0
    const increment = end / (duration * 60) // 60 FPS
    const timer = setInterval(() => {
      start += increment
      if (start >= end) {
        setCount(end)
        clearInterval(timer)
      } else {
        setCount(Math.floor(start))
      }
    }, 1000 / 60)

    return () => clearInterval(timer)
  }, [inView, end, duration])

  return <span ref={ref}>{count.toLocaleString()}</span>
}

export default CountUp
