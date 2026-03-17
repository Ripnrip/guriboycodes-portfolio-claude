import { useEffect, useState } from 'react'

const useEasterEgg = (onTrigger) => {
  const [clickCount, setClickCount] = useState(0)
  const konami = ['ArrowUp', 'ArrowUp', 'ArrowDown', 'ArrowDown', 'ArrowLeft', 'ArrowRight', 'ArrowLeft', 'ArrowRight', 'b', 'a']
  const [konamiIndex, setKonamiIndex] = useState(0)

  useEffect(() => {
    const handleKeyDown = (e) => {
      if (e.key === konami[konamiIndex]) {
        setKonamiIndex(konamiIndex + 1)
        if (konamiIndex + 1 === konami.length) {
          onTrigger()
          setKonamiIndex(0)
        }
      } else {
        setKonamiIndex(0)
      }
    }

    window.addEventListener('keydown', handleKeyDown)
    return () => window.removeEventListener('keydown', handleKeyDown)
  }, [konamiIndex])

  const handleProfileClick = () => {
    setClickCount(clickCount + 1)
    if (clickCount + 1 === 5) {
      onTrigger()
      setClickCount(0)
    }
  }

  return { handleProfileClick, clickCount }
}

export default useEasterEgg
