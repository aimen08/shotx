import Footer from './components/Footer.jsx';
import { HeroClassicSection, HeroProductSection } from './components/Heroes.jsx';
import { FeaturesSection, ShortcutsSection, CTASection } from './components/Sections.jsx';

const PAGE_BG = '#050710';

export default function App() {
  return (
    <div
      style={{
        backgroundColor: PAGE_BG,
        backgroundImage:
          'linear-gradient(rgba(255,255,255,.028) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.028) 1px, transparent 1px)',
        backgroundSize: '48px 48px',
        color: '#fff',
        overflowX: 'hidden',
      }}
    >
      <HeroClassicSection />

      <FeaturesSection />

      <HeroProductSection />

      <ShortcutsSection />
      <CTASection />
      <Footer />
    </div>
  );
}
