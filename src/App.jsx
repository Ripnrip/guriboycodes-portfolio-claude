import React from 'react'
import Navigation from './components/Navigation'
import Hero from './components/Hero'
import Stats from './components/Stats'
import ScrollingTicker from './components/ScrollingTicker'
import Skills from './components/Skills'
import CareerJourney from './components/CareerJourney'
import Philosophy from './components/Philosophy'
import Projects from './components/Projects'
import Hackathons from './components/Hackathons'
import FeaturedVideos from './components/FeaturedVideos'
import Leadership from './components/Leadership'
import Contact from './components/Contact'

function App() {
  return (
    <div className="min-h-screen bg-paper text-ink">
      <Navigation />
      <main>
        <Hero />
        <Stats />
        <ScrollingTicker />
        <Skills />
        <CareerJourney />
        <Philosophy />
        <Projects />
        <Hackathons />
        <FeaturedVideos />
        <Leadership />
        <Contact />
      </main>
    </div>
  )
}

export default App
