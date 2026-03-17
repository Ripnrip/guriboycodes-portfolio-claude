const CDN_BASE = 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio-claude/main/public'

export const hackathons = [
  {
    id: 1,
    name: 'HackZurich 2022',
    year: 2022,
    project: 'Elate',
    description: 'Built an AI-powered wellness platform that earned a finalist spot at Europe\'s largest hackathon.',
    image: `${CDN_BASE}/images/thumbnails/hackzurich-2022-elate.jpg`,
    videoUrl: `${CDN_BASE}/videos/hackzurich-2022-elate-720p.mp4`,
    award: 'Finalist',
    technologies: ['React', 'AI/ML', 'Python'],
  },
  {
    id: 2,
    name: 'HackZurich 2021',
    year: 2021,
    project: 'ARon — AI Fitness Coach',
    description: 'AR-powered fitness companion with real-time form correction using AI pose estimation.',
    image: `${CDN_BASE}/images/thumbnails/hackzurich-2021-aron.jpg`,
    videoUrl: `${CDN_BASE}/videos/hackzurich-2021-aron-fitness.mp4`,
    award: 'Finalist',
    technologies: ['ARKit', 'Swift', 'AI/ML'],
  },
  {
    id: 3,
    name: 'HackZurich 2018',
    year: 2018,
    project: 'Carly — AR Car Visualizer',
    description: 'Augmented reality car shopping experience letting you place life-size cars in your driveway.',
    image: `${CDN_BASE}/images/thumbnails/hackzurich-2018.jpg`,
    videoUrl: 'https://raw.githubusercontent.com/Ripnrip/guriboycodes-portfolio/claude-portfolio/public/videos/hackzurich-carly.mp4',
    award: 'Finalist',
    technologies: ['ARKit', 'Swift', 'USDZ'],
  },
  {
    id: 4,
    name: 'MLH Prime 2017',
    year: 2017,
    project: 'London Drone — BBC Documentary',
    description: 'Autonomous drone coordination project that was featured on a BBC documentary. 1st place at MLH Prime.',
    image: `${CDN_BASE}/images/thumbnails/mlh-2017-drone.jpg`,
    videoUrl: `${CDN_BASE}/videos/mlh-2017-drone-bbc.mp4`,
    award: '1st Place',
    technologies: ['Robotics', 'Python', 'Autonomous Systems'],
  },
]

export const getTotalHackathons = () => hackathons.length
