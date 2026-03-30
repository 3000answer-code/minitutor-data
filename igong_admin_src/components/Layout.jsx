import { useState } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'

const MENU = [
  {
    key: 'members', label: '회원', icon: '👥',
    children: [
      { key: 'members', label: '회원 목록', path: '/members' },
      { key: 'members/payments', label: '결제 회원', path: '/members/payments' },
      { key: 'members/stats', label: '회원 통계', path: '/members/stats' },
    ]
  },
  {
    key: 'videos', label: '동영상 백과', icon: '🎬',
    children: [
      { key: 'videos/instructors', label: '강사 목록', path: '/videos/instructors' },
      { key: 'videos/series', label: '시리즈 목록', path: '/videos/series' },
      { key: 'videos/list', label: '동영상 목록', path: '/videos/list' },
      { key: 'videos/stats', label: '동영상 통계', path: '/videos/stats' },
      { key: 'videos/qa', label: '강의 Q&A', path: '/videos/qa' },
    ]
  },
  {
    key: 'consultation', label: '전문가 상담', icon: '💬',
    children: [
      { key: 'consultation/experts', label: '전문가 목록', path: '/consultation/experts' },
      { key: 'consultation/list', label: '상담 목록', path: '/consultation/list' },
    ]
  },
  {
    key: 'notice', label: '공지사항', icon: '📢',
    children: [
      { key: 'notice/list', label: '공만세 공지', path: '/notice/list' },
      { key: 'notice/events', label: '행사/이벤트', path: '/notice/events' },
    ]
  },
  {
    key: 'support', label: '고객센터', icon: '🎧',
    children: [
      { key: 'support/faq', label: 'FAQ', path: '/support/faq' },
      { key: 'support/inquiry', label: '1:1 문의', path: '/support/inquiry' },
    ]
  },
  {
    key: 'coupon', label: '쿠폰', icon: '🎟️',
    children: [
      { key: 'coupon', label: '쿠폰 목록', path: '/coupon' },
    ]
  },
  {
    key: 'admin', label: '관리', icon: '⚙️',
    children: [
      { key: 'admin/banners', label: '홈 배너 관리', path: '/admin/banners' },
      { key: 'admin/list', label: '관리자 목록', path: '/admin/list' },
      { key: 'admin/push', label: '푸시 알림', path: '/admin/push' },
    ]
  },
]

export default function Layout({ children, adminInfo, onLogout }) {
  const navigate = useNavigate()
  const location = useLocation()
  const [openMenus, setOpenMenus] = useState({ members: true, videos: false, consultation: false, notice: false, support: false, coupon: false, admin: false })

  const toggleMenu = (key) => {
    setOpenMenus(prev => ({ ...prev, [key]: !prev[key] }))
  }

  const isActive = (path) => location.pathname === path

  return (
    <div style={styles.root}>
      {/* 사이드바 */}
      <aside style={styles.sidebar}>
        <div style={styles.sidebarTop}>
          <div style={styles.sideLogoIcon}>이공</div>
          <div>
            <div style={styles.sideLogoText}>2공 관리자</div>
            <div style={styles.sideLogoSub}>Admin Console</div>
          </div>
        </div>
        <div style={styles.adminBadge}>
          <span style={styles.adminDot}></span>
          <span>{adminInfo?.name || '관리자'}</span>
        </div>
        <nav style={styles.nav}>
          <div
            style={{ ...styles.navItem, ...(location.pathname === '/dashboard' ? styles.navItemActive : {}) }}
            onClick={() => navigate('/dashboard')}
          >
            <span>📊</span><span>대시보드</span>
          </div>
          {MENU.map(menu => (
            <div key={menu.key}>
              <div style={styles.navGroup} onClick={() => toggleMenu(menu.key)}>
                <span>{menu.icon}</span>
                <span style={{ flex: 1 }}>{menu.label}</span>
                <span style={{ fontSize: 11, opacity: 0.6 }}>{openMenus[menu.key] ? '▲' : '▼'}</span>
              </div>
              {openMenus[menu.key] && menu.children.map(child => (
                <div
                  key={child.key}
                  style={{ ...styles.navSub, ...(isActive(child.path) ? styles.navSubActive : {}) }}
                  onClick={() => navigate(child.path)}
                >
                  {child.label}
                </div>
              ))}
            </div>
          ))}
        </nav>
        <div style={styles.sidebarBottom}>
          <button style={styles.logoutBtn} onClick={onLogout}>🚪 로그아웃</button>
        </div>
      </aside>

      {/* 메인 */}
      <div style={styles.main}>
        <header style={styles.header}>
          <div style={styles.headerLeft}>
            <span style={styles.headerTitle}>
              {MENU.flatMap(m => m.children).find(c => isActive(c.path))?.label || '대시보드'}
            </span>
          </div>
          <div style={styles.headerRight}>
            <span style={styles.headerUser}>👤 {adminInfo?.name}</span>
            <a href="/" style={styles.headerBtn}>🏠 홈페이지</a>
          </div>
        </header>
        <main style={styles.content}>{children}</main>
      </div>
    </div>
  )
}

const styles = {
  root: { display: 'flex', minHeight: '100vh', background: '#f0f2f5' },
  sidebar: {
    width: 220, background: 'linear-gradient(180deg, #1a1a2e 0%, #16213e 100%)',
    display: 'flex', flexDirection: 'column', flexShrink: 0,
    position: 'sticky', top: 0, height: '100vh', overflowY: 'auto',
  },
  sidebarTop: {
    display: 'flex', alignItems: 'center', gap: 12,
    padding: '24px 16px 16px',
    borderBottom: '1px solid rgba(255,255,255,0.08)',
  },
  sideLogoIcon: {
    width: 40, height: 40,
    background: 'linear-gradient(135deg, #4f46e5, #7c3aed)',
    borderRadius: 10,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    fontSize: 13, fontWeight: 900, color: '#fff', flexShrink: 0,
  },
  sideLogoText: { fontSize: 15, fontWeight: 800, color: '#fff' },
  sideLogoSub: { fontSize: 10, color: 'rgba(255,255,255,0.4)', marginTop: 2 },
  adminBadge: {
    display: 'flex', alignItems: 'center', gap: 8,
    padding: '10px 16px',
    fontSize: 12, color: 'rgba(255,255,255,0.6)',
  },
  adminDot: {
    width: 7, height: 7, borderRadius: '50%',
    background: '#4ade80', display: 'inline-block',
  },
  nav: { flex: 1, padding: '8px 0', overflowY: 'auto' },
  navItem: {
    display: 'flex', alignItems: 'center', gap: 10,
    padding: '10px 16px', cursor: 'pointer',
    color: 'rgba(255,255,255,0.7)', fontSize: 14,
    borderRadius: 8, margin: '2px 8px',
    transition: 'all 0.2s',
  },
  navItemActive: {
    background: 'linear-gradient(135deg, #4f46e5, #7c3aed)',
    color: '#fff',
  },
  navGroup: {
    display: 'flex', alignItems: 'center', gap: 10,
    padding: '10px 16px', cursor: 'pointer',
    color: 'rgba(255,255,255,0.85)', fontSize: 13, fontWeight: 600,
    borderRadius: 8, margin: '2px 8px',
  },
  navSub: {
    padding: '8px 16px 8px 44px',
    cursor: 'pointer', color: 'rgba(255,255,255,0.5)', fontSize: 13,
    borderRadius: 6, margin: '1px 8px',
    transition: 'all 0.2s',
  },
  navSubActive: {
    background: 'rgba(79,70,229,0.25)',
    color: '#a5b4fc',
  },
  sidebarBottom: {
    padding: '16px',
    borderTop: '1px solid rgba(255,255,255,0.08)',
  },
  logoutBtn: {
    width: '100%', padding: '10px',
    background: 'rgba(255,255,255,0.08)',
    color: 'rgba(255,255,255,0.6)',
    borderRadius: 8, fontSize: 13,
    transition: 'background 0.2s',
  },
  main: { flex: 1, display: 'flex', flexDirection: 'column', overflow: 'hidden' },
  header: {
    background: '#fff', padding: '0 24px', height: 60,
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    boxShadow: '0 1px 3px rgba(0,0,0,0.08)',
    position: 'sticky', top: 0, zIndex: 10,
  },
  headerLeft: {},
  headerTitle: { fontSize: 16, fontWeight: 700, color: '#1a1a2e' },
  headerRight: { display: 'flex', alignItems: 'center', gap: 16 },
  headerUser: { fontSize: 13, color: '#555' },
  headerBtn: {
    padding: '6px 14px',
    background: '#f0f2f5',
    borderRadius: 6, fontSize: 12,
    color: '#555',
  },
  content: { flex: 1, padding: '24px', overflowY: 'auto' },
}
