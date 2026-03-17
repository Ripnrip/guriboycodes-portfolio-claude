import React, { useState, useEffect } from 'react'
import { Moon, Sun } from 'lucide-react'
import Navigation from './components/Navigation'
import Hero from './components/Hero'
import Stats from './components/Stats'
import ScrollingTicker from './components/ScrollingTicker'
import CareerJourney from './components/CareerJourney'
import Philosophy from './components/Philosophy'
import Projects from './components/Projects'
import Hackathons from './components/Hackathons'
import Contact from './components/Contact'

function App() {
  const [darkMode, setDarkMode] = useState(true)

  useEffect(() => {
    if (darkMode) {
      document.documentElement.classList.add('dark')
    } else {
      document.documentElement.classList.remove('dark')
    }
  }, [darkMode])

  return (
    <div className="min-h-screen bg-claude-dark text-claude-text">
      <Navigation darkMode={darkMode} setDarkMode={setDarkMode} />
      <main>
        <Hero />
        <Stats />
        <ScrollingTicker />
        <CareerJourney />
        <Philosophy />
        <Projects />
        <Hackathons />
        <Contact />
      </main>
    </div>
  )
}

export default App
