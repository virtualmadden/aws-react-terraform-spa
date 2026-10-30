import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import App from './App'

describe('App', () => {
  it('renders the landing page', () => {
    render(<App />)
    expect(screen.getByRole('heading', { level: 1 })).toHaveTextContent('Your SPA is live.')
  })

  it('counts clicks', async () => {
    render(<App />)
    const button = screen.getByRole('button')
    expect(button).toHaveTextContent('Clicked 0 times')
    await userEvent.click(button)
    expect(button).toHaveTextContent('Clicked 1 time')
  })
})
