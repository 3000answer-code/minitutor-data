export default function PageHeader({ title, subtitle, actions }) {
  return (
    <div style={s.header}>
      <div>
        <h2 style={s.title}>{title}</h2>
        {subtitle && <p style={s.sub}>{subtitle}</p>}
      </div>
      {actions && <div style={s.actions}>{actions}</div>}
    </div>
  )
}

export function Card({ children, style }) {
  return <div style={{ ...s.card, ...style }}>{children}</div>
}

export function Btn({ children, onClick, type = 'primary', size = 'md', disabled }) {
  const colors = {
    primary: { bg: '#4f46e5', color: '#fff' },
    danger: { bg: '#dc2626', color: '#fff' },
    success: { bg: '#16a34a', color: '#fff' },
    secondary: { bg: '#f3f4f6', color: '#333' },
    outline: { bg: '#fff', color: '#4f46e5', border: '1.5px solid #4f46e5' },
  }
  const sizes = {
    sm: { padding: '5px 12px', fontSize: 12 },
    md: { padding: '8px 18px', fontSize: 13 },
    lg: { padding: '12px 24px', fontSize: 15 },
  }
  const c = colors[type] || colors.primary
  const sz = sizes[size] || sizes.md
  return (
    <button
      onClick={onClick}
      disabled={disabled}
      style={{
        ...s.btn, ...sz,
        background: c.bg, color: c.color,
        border: c.border || 'none',
        opacity: disabled ? 0.5 : 1,
      }}
    >
      {children}
    </button>
  )
}

export function Modal({ open, onClose, title, children, width = 520 }) {
  if (!open) return null
  return (
    <div style={s.overlay} onClick={onClose}>
      <div style={{ ...s.modal, width }} onClick={e => e.stopPropagation()}>
        <div style={s.modalHeader}>
          <span style={s.modalTitle}>{title}</span>
          <button style={s.closeBtn} onClick={onClose}>✕</button>
        </div>
        <div style={s.modalBody}>{children}</div>
      </div>
    </div>
  )
}

export function FormField({ label, children, required }) {
  return (
    <div style={s.formField}>
      <label style={s.formLabel}>{label}{required && <span style={{ color: '#dc2626' }}> *</span>}</label>
      {children}
    </div>
  )
}

export function Input({ value, onChange, placeholder, type = 'text', style }) {
  return (
    <input
      type={type}
      value={value}
      onChange={onChange}
      placeholder={placeholder}
      style={{ ...s.input, ...style }}
    />
  )
}

export function Select({ value, onChange, options, style }) {
  return (
    <select value={value} onChange={onChange} style={{ ...s.select, ...style }}>
      {options.map(o => <option key={o.value} value={o.value}>{o.label}</option>)}
    </select>
  )
}

export function Textarea({ value, onChange, placeholder, rows = 4, style }) {
  return (
    <textarea
      value={value}
      onChange={onChange}
      placeholder={placeholder}
      rows={rows}
      style={{ ...s.input, resize: 'vertical', ...style }}
    />
  )
}

export function StatCard({ icon, label, value, sub, color = '#4f46e5' }) {
  return (
    <div style={s.statCard}>
      <div style={{ ...s.statIcon, background: color + '18', color }}>{icon}</div>
      <div>
        <div style={s.statLabel}>{label}</div>
        <div style={{ ...s.statValue, color }}>{value}</div>
        {sub && <div style={s.statSub}>{sub}</div>}
      </div>
    </div>
  )
}

const s = {
  header: {
    display: 'flex', alignItems: 'flex-start',
    justifyContent: 'space-between', marginBottom: 20,
  },
  title: { fontSize: 20, fontWeight: 800, color: '#1a1a2e' },
  sub: { fontSize: 13, color: '#888', marginTop: 4 },
  actions: { display: 'flex', gap: 8 },
  card: {
    background: '#fff', borderRadius: 14,
    padding: '20px 24px',
    boxShadow: '0 1px 4px rgba(0,0,0,0.06)',
    marginBottom: 20,
  },
  btn: {
    borderRadius: 8, fontWeight: 600,
    cursor: 'pointer', transition: 'opacity 0.2s',
    display: 'inline-flex', alignItems: 'center', gap: 6,
  },
  overlay: {
    position: 'fixed', inset: 0,
    background: 'rgba(0,0,0,0.5)',
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    zIndex: 1000,
  },
  modal: {
    background: '#fff', borderRadius: 16,
    boxShadow: '0 20px 60px rgba(0,0,0,0.2)',
    maxHeight: '90vh', display: 'flex', flexDirection: 'column',
  },
  modalHeader: {
    display: 'flex', alignItems: 'center', justifyContent: 'space-between',
    padding: '20px 24px', borderBottom: '1px solid #f0f0f0',
  },
  modalTitle: { fontSize: 16, fontWeight: 700 },
  closeBtn: {
    background: 'none', fontSize: 18, color: '#888', cursor: 'pointer',
  },
  modalBody: { padding: '20px 24px', overflowY: 'auto', flex: 1 },
  formField: { marginBottom: 16 },
  formLabel: { display: 'block', fontSize: 13, fontWeight: 600, color: '#555', marginBottom: 6 },
  input: {
    width: '100%', padding: '10px 14px',
    border: '1.5px solid #e0e0e0', borderRadius: 8,
    fontSize: 13, fontFamily: 'inherit',
  },
  select: {
    width: '100%', padding: '10px 14px',
    border: '1.5px solid #e0e0e0', borderRadius: 8,
    fontSize: 13, background: '#fff', fontFamily: 'inherit',
  },
  statCard: {
    background: '#fff', borderRadius: 14,
    padding: '20px 24px',
    boxShadow: '0 1px 4px rgba(0,0,0,0.06)',
    display: 'flex', alignItems: 'center', gap: 16,
  },
  statIcon: {
    width: 52, height: 52, borderRadius: 14,
    display: 'flex', alignItems: 'center', justifyContent: 'center',
    fontSize: 24, flexShrink: 0,
  },
  statLabel: { fontSize: 12, color: '#888', marginBottom: 4 },
  statValue: { fontSize: 24, fontWeight: 800 },
  statSub: { fontSize: 11, color: '#aaa', marginTop: 2 },
}
