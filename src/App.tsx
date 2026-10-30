import { useState } from 'react'

function App() {
  const [count, setCount] = useState(0)

  return (
    <main className='page'>
      <p className='eyebrow'>S3 + CloudFront + Terraform</p>
      <h1>Your SPA is live.</h1>
      <p className='lead'>
        Edit <code>src/App.tsx</code> and push to <code>main</code> to deploy.
      </p>
      <button type='button' onClick={() => setCount((n) => n + 1)}>
        Clicked {count} {count === 1 ? 'time' : 'times'}
      </button>
    </main>
  )
}

export default App
