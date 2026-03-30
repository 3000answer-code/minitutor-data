import { useState } from 'react'

export default function LoginPage({ onLogin }) {
  const [id, setId] = useState('')
  const [pw, setPw] = useState('')
  const [error, setError] = useState('')

  const handleLogin = (e) => {
    e.preventDefault()
    if (id === 'admin' && pw === 'admin1234') {
      onLogin({ name: '슈퍼관리자', userId: id })
    } else if (id === 'content01' && pw === '1234') {
      onLogin({ name: '콘텐츠담당', userId: id })
    } else {
      setError('아이디 또는 비밀번호를 다시 확인하세요')
    }
  }

  return (
    <div style={styles.bg}>
      <div style={styles.card}>
        <div style={styles.logoArea}>
          <div style={styles.logoIcon}>이공</div>
          <div style={styles.logoText}>2공 관리자</div>
          <div style={styles.logoSub}>Admin Console</div>
        </div>
        <form onSubmit={handleLogin} style={styles.form}>
          <div style={styles.field}>
            <label style={styles.label}>아이디</label>
            <input
              style={styles.input}
              type="text"
              placeholder="관리자 아이디를 입력하세요"
              value={id}
              onChange={e => { setId(e.target.value); setError('') }}
              autoFocus
            />
          </div>
          <div style={styles.field}>
            <label style={styles.label}>비밀번호</label>
            <input
              style={styles.input}
              type="password"
              placeholder="비밀번호를 입력하세요"
              value={pw}
              onChange={e => { setPw(e.target.value); setError('') }}
            />
          </div>
          {error && <div style={styles.error}>{error}</div>}
          <button type="submit" style={styles.btn}>로그인</button>
        </form>
        <div style={styles.hint}>
          <span>테스트 계정: admin / admin1234</span>
        </div>
      </div>
    </div>
  )
}

const styles = {
  bg: {
    minHeight: '100vh',
    background: 'linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
  },
  card: {
    background: '#fff',
    borderRadius: 20,
    padding: '48px 40px',
    width: 400,
    boxShadow: '0 20px 60px rgba(0,0,0,0.3)',
  },
  logoArea: {
    textAlign: 'center', marginBottom: 36,
  },
  logoIcon: {
    width: 72, height: 72,
    background: 'linear-gradient(135deg, #4f46e5, #7c3aed)',
    borderRadius: 20,
    display: 'inline-flex', alignItems: 'center', justifyContent: 'center',
    fontSize: 24, fontWeight: 900, color: '#fff',
    marginBottom: 12,
  },
  logoText: {
    fontSize: 24, fontWeight: 900, color: '#1a1a2e',
  },
  logoSub: {
    fontSize: 13, color: '#888', marginTop: 4,
  },
  form: { display: 'flex', flexDirection: 'column', gap: 16 },
  field: { display: 'flex', flexDirection: 'column', gap: 6 },
  label: { fontSize: 13, fontWeight: 600, color: '#555' },
  input: {
    padding: '12px 16px',
    border: '1.5px solid #e0e0e0',
    borderRadius: 10,
    fontSize: 14,
    transition: 'border-color 0.2s',
  },
  error: {
    background: '#fff0f0',
    border: '1px solid #ffcccc',
    borderRadius: 8,
    padding: '10px 14px',
    color: '#e53e3e',
    fontSize: 13,
    textAlign: 'center',
  },
  btn: {
    marginTop: 8,
    padding: '14px',
    background: 'linear-gradient(135deg, #4f46e5, #7c3aed)',
    color: '#fff',
    borderRadius: 10,
    fontSize: 15,
    fontWeight: 700,
    letterSpacing: 1,
    transition: 'opacity 0.2s',
  },
  hint: {
    marginTop: 20,
    textAlign: 'center',
    fontSize: 12,
    color: '#aaa',
  },
}
