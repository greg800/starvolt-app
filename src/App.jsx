import { useState, useEffect, useRef, useCallback } from 'react';
import Logo from './Logo.jsx';
import MapACC from './MapACC.jsx';
import Fireworks from './Fireworks.jsx';

// ─────────────────────────────────────────────
// HOOK — Animated number counter
// ─────────────────────────────────────────────
function useAnimatedBill(target) {
  const [current, setCurrent] = useState(target);
  const fromRef = useRef(target);
  const rafRef  = useRef(null);

  useEffect(() => {
    if (fromRef.current === target) return;
    const from = fromRef.current;
    const duration = 1400;
    const start = performance.now();

    const animate = (now) => {
      const t = Math.min((now - start) / duration, 1);
      const eased = 1 - Math.pow(1 - t, 4); // ease-out quart
      setCurrent(Math.round(from + (target - from) * eased));
      if (t < 1) {
        rafRef.current = requestAnimationFrame(animate);
      } else {
        fromRef.current = target;
      }
    };

    rafRef.current = requestAnimationFrame(animate);
    return () => rafRef.current && cancelAnimationFrame(rafRef.current);
  }, [target]);

  return current;
}

// ─────────────────────────────────────────────
// COMPONENT — Bill Meter
// ─────────────────────────────────────────────
function BillMeter({ bill, initialBill }) {
  const displayed  = useAnimatedBill(bill);
  const isSaving   = bill < initialBill;
  const savedSoFar = initialBill - bill;

  return (
    <div className="bill-meter">
      <div className="bill-label">Votre facture annuelle</div>
      <div className="bill-amount-row">
        <span className={`bill-amount ${isSaving ? 'saving' : ''}`}>
          {displayed.toLocaleString('fr-FR')}
        </span>
        <span className="bill-currency">€</span>
      </div>
      <div className="bill-period">par an</div>
      {isSaving && (
        <div className="savings-badge">
          🌱 Économies : {savedSoFar.toLocaleString('fr-FR')} €/an
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────
// COMPONENT — Back button
// ─────────────────────────────────────────────
function BackButton({ onBack }) {
  return (
    <button className="back-btn" onClick={onBack}>
      ← Retour
    </button>
  );
}

// ─────────────────────────────────────────────
// SCREEN — Welcome
// ─────────────────────────────────────────────
function WelcomeScreen({ state, onStart }) {
  const [name, setName] = useState(state.name);
  const [city, setCity] = useState(state.city);
  const [bill, setBill] = useState(state.initialBill);

  return (
    <div className="screen fade-in">
      <div className="welcome-header">
        <div className="welcome-tagline">Simulation personnalisée</div>
        <h1 className="welcome-title">
          Combien pouvez-vous<br />économiser avec<br />
          <span className="accent">Starvolt</span> ?
        </h1>
        <p className="welcome-subtitle">
          Répondez à quelques questions et regardez votre facture fondre.
        </p>
      </div>

      <div className="form-card">
        <div className="input-group">
          <label className="input-label">Votre nom</label>
          <input
            className="input-field"
            value={name}
            onChange={e => setName(e.target.value)}
            placeholder="Marie Dupont"
          />
        </div>
        <div className="input-group">
          <label className="input-label">Votre ville</label>
          <input
            className="input-field"
            value={city}
            onChange={e => setCity(e.target.value)}
            placeholder="Lyon"
          />
        </div>
        <div className="input-group">
          <label className="input-label">Facture électricité (€/an)</label>
          <div className="bill-input-wrapper">
            <input
              className="input-field"
              type="number"
              value={bill}
              onChange={e => setBill(Math.max(0, Number(e.target.value) || 0))}
              min="0"
              max="20000"
            />
            <span className="bill-input-suffix">€/an</span>
          </div>
        </div>
      </div>

      <button
        className="btn btn-primary"
        onClick={() => onStart({ name: name || 'Marie Dupont', city: city || 'Lyon', bill: bill || 2000 })}
      >
        Calculer mes économies →
      </button>
    </div>
  );
}

// ─────────────────────────────────────────────
// SCREEN — Address check
// ─────────────────────────────────────────────
function AddressScreen({ state, onHasACC, onNoACC, onBack }) {
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const t = setTimeout(() => setLoading(false), 1800);
    return () => clearTimeout(t);
  }, []);

  return (
    <div className="screen fade-in">
      <BackButton onBack={onBack} />
      <BillMeter bill={state.bill} initialBill={state.initialBill} />

      {loading ? (
        <div className="loading-card fade-in">
          <div className="spinner" />
          <p>Vérification de votre adresse…</p>
          <p className="loading-sub">📍 {state.city}</p>
        </div>
      ) : (
        <div className="card fade-in">
          <div className="address-found">
            <div className="address-icon">🏠</div>
            <div className="address-text">
              <strong>{state.name}</strong>
              <span>{state.city}</span>
            </div>
          </div>

          <h2 className="screen-title">Votre logement est-il dans une boucle ACC ?</h2>
          <p className="screen-subtitle">
            Une boucle d'autoconsommation collective (ACC) permet de partager l'énergie locale
            entre producteurs et consommateurs à moins de 2 km.
          </p>

          <div className="btn-group">
            <button className="btn btn-yes" onClick={onHasACC}>
              ✅ Oui, je suis dans une boucle ACC
            </button>
            <button className="btn btn-no" onClick={onNoACC}>
              ❌ Non, pas encore
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ─────────────────────────────────────────────
// SCREEN — ACC Map
// ─────────────────────────────────────────────
function ACCMapScreen({ state, onContinue, onBack }) {
  return (
    <div className="screen fade-in">
      <BackButton onBack={onBack} />
      <BillMeter bill={state.bill} initialBill={state.initialBill} />

      <div className="card">
        <div className="badge success">✨ Excellente nouvelle !</div>
        <h2 className="screen-title">Votre logement est dans une boucle ACC</h2>
        <p className="screen-subtitle">
          Vous partagez de l'énergie locale avec des producteurs situés à moins de 2 km de chez vous.
        </p>

        <MapACC />

        <div className="map-legend">
          <div className="legend-item">
            <div className="legend-dot house">🏠</div>
            <span>Logement de {state.name.split(' ')[0]}</span>
          </div>
          <div className="legend-item">
            <div className="legend-dot pv">☀️</div>
            <span>Site de production photovoltaïque</span>
          </div>
          <div className="legend-item">
            <div className="legend-dot zone">⬤</div>
            <span>Zone ACC — rayon de 2 km</span>
          </div>
        </div>

        <button className="btn btn-primary" onClick={onContinue}>
          Voir mon tarif ACC →
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// SCREEN — ACC Tariff question
// ─────────────────────────────────────────────
function ACCTariffScreen({ state, onYes, onNo, onBack }) {
  return (
    <div className="screen fade-in">
      <BackButton onBack={onBack} />
      <BillMeter bill={state.bill} initialBill={state.initialBill} />

      <div className="card">
        <h2 className="screen-title">Votre tarif ACC</h2>
        <p className="screen-subtitle">
          En rejoignant la boucle ACC, vous accédez à un tarif d'électricité préférentiel fourni par le producteur local.
        </p>

        <div className="tariff-display">
          <div className="tariff-item">
            <span className="tariff-label">Tarif actuel (fournisseur)</span>
            <span className="tariff-value old">~0,25 €/kWh</span>
          </div>
          <div className="tariff-arrow">↓</div>
          <div className="tariff-item">
            <span className="tariff-label">Tarif ACC disponible</span>
            <span className="tariff-value new">~0,16 €/kWh</span>
          </div>
        </div>

        <div className="saving-estimate">
          <div className="saving-label">Économie estimée</div>
          <div className="saving-amount">185 €<span style={{ fontSize: 20, fontWeight: 600 }}>/an</span></div>
          <div className="saving-note">Sans aucun investissement</div>
        </div>

        <h3 className="question-title">Le tarif ACC vous intéresse-t-il ?</h3>

        <div className="btn-group">
          <button className="btn btn-yes" onClick={onYes}>
            ✅ Oui, c'est intéressant !
          </button>
          <button className="btn btn-no" onClick={onNo}>
            ❌ Non, pas pour moi
          </button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// SCREEN — Not interested in ACC tariff
// ─────────────────────────────────────────────
function NotInterestedScreen({ state, onContinue, onBack }) {
  return (
    <div className="screen fade-in">
      <BackButton onBack={onBack} />
      <BillMeter bill={state.bill} initialBill={state.initialBill} />

      <div className="card">
        <div className="badge info">👀 Pas de problème</div>
        <h2 className="screen-title">Nous restons attentifs</h2>
        <p className="screen-subtitle">
          Nous suivons l'évolution des tarifs ACC et nous vous recontacterons dès qu'une offre
          mieux adaptée à votre profil sera disponible.
        </p>

        <button className="btn btn-primary" onClick={onContinue}>
          Voir d'autres options →
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// SCREEN — No ACC in the area
// ─────────────────────────────────────────────
function NoACCScreen({ state, onContinue, onBack }) {
  return (
    <div className="screen fade-in">
      <BackButton onBack={onBack} />
      <BillMeter bill={state.bill} initialBill={state.initialBill} />

      <div className="card">
        <div className="badge info">💡 Pas encore… mais bientôt !</div>
        <h2 className="screen-title">Créons votre boucle ACC</h2>
        <p className="screen-subtitle">
          Il n'y a pas encore de boucle ACC dans votre secteur, mais Starvolt peut en créer une
          autour de votre logement.
        </p>

        <div className="steps-list">
          <div className="step-item">
            <div className="step-number">1</div>
            <div className="step-text">Starvolt référence votre logement comme point de consommation</div>
          </div>
          <div className="step-item">
            <div className="step-number">2</div>
            <div className="step-text">D'autres citoyens et collectivités rejoignent la boucle</div>
          </div>
          <div className="step-item">
            <div className="step-number">3</div>
            <div className="step-text">Vous commencez à économiser dès que la boucle est activée</div>
          </div>
        </div>

        <button className="btn btn-primary" onClick={onContinue}>
          Continuer la simulation →
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// SCREEN — Comwatt Box
// ─────────────────────────────────────────────
function ComwattScreen({ state, onYes, onNo, onBack }) {
  return (
    <div className="screen fade-in">
      <BackButton onBack={onBack} />
      <BillMeter bill={state.bill} initialBill={state.initialBill} />

      <div className="card">
        <div className="device-icon">📦</div>
        <h2 className="screen-title">Box Comwatt</h2>
        <p className="screen-subtitle">
          La box Comwatt maximise l'énergie ACC que vous consommez et alimente votre cagnotte flexibilité.
        </p>

        <div className="offer-card">
          <div className="offer-row">
            <span className="offer-label">Gain annuel supplémentaire</span>
            <span className="offer-value green">+ 200 €/an</span>
          </div>
          <div className="offer-divider" />
          <div className="offer-row">
            <span className="offer-label">Investissement initial</span>
            <span className="offer-value">550 € TTC</span>
          </div>
          <div className="offer-promo">
            🎁 Ou <strong>gratuit</strong> si vous renoncez à votre cagnotte Flex pendant 3 ans
          </div>
        </div>

        <h3 className="question-title">Souhaitez-vous installer une box Comwatt ?</h3>

        <div className="btn-group">
          <button className="btn btn-yes" onClick={onYes}>
            ✅ Oui, je veux la box !
          </button>
          <button className="btn btn-no" onClick={onNo}>
            ❌ Non merci
          </button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// SCREEN — Solar panels
// ─────────────────────────────────────────────
function SolarScreen({ state, onYes, onNo, onBack }) {
  return (
    <div className="screen fade-in">
      <BackButton onBack={onBack} />
      <BillMeter bill={state.bill} initialBill={state.initialBill} />

      <div className="card">
        <div className="device-icon">☀️</div>
        <h2 className="screen-title">Panneaux solaires + Batterie</h2>
        <p className="screen-subtitle">
          Produisez votre propre électricité et stockez l'excédent. La solution la plus ambitieuse pour votre indépendance énergétique.
        </p>

        <div className="offer-card">
          <div className="offer-row">
            <span className="offer-label">Réduction de facture</span>
            <span className="offer-value green">− 1 000 €/an</span>
          </div>
          <div className="offer-divider" />
          <div className="offer-row">
            <span className="offer-label">Investissement initial</span>
            <span className="offer-value">10 000 € TTC</span>
          </div>
        </div>

        <h3 className="question-title">Souhaitez-vous investir dans le solaire ?</h3>

        <div className="btn-group">
          <button className="btn btn-yes" onClick={onYes}>
            ✅ Oui, je veux le solaire !
          </button>
          <button className="btn btn-no" onClick={onNo}>
            ❌ Non, peut-être plus tard
          </button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// SCREEN — Bravo
// ─────────────────────────────────────────────
function BravoScreen({ state, stepNumber, saving, label, onContinue, onBack }) {
  return (
    <div className="screen fade-in">
      <Fireworks />
      <BackButton onBack={onBack} />
      <BillMeter bill={state.bill} initialBill={state.initialBill} />

      <div className="card bravo-card">
        <div className="bravo-step-number">{stepNumber}</div>
        <h1 className="bravo-title">BRAVO !</h1>
        <p className="bravo-subtitle">En un seul clic vous venez de gagner</p>
        <div className="bravo-saving-row">
          <span className="bravo-saving-amount">+{saving.toLocaleString('fr-FR')} €</span>
          <span className="bravo-saving-period">par an</span>
        </div>
        <p className="bravo-label">{label}</p>

        <button className="btn btn-primary" onClick={onContinue}>
          Continuer →
        </button>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// SCREEN — Final
// ─────────────────────────────────────────────
function FinalScreen({ state, onRestart }) {
  const savings = state.initialBill - state.bill;

  return (
    <div className="screen fade-in">
      <Fireworks final />
      <BillMeter bill={state.bill} initialBill={state.initialBill} />

      <div className="card">
        <h2 className="screen-title" style={{ marginBottom: 4 }}>Récapitulatif</h2>
        <p className="screen-subtitle" style={{ marginBottom: 0 }}>
          Voici ce que Starvolt peut faire pour {state.name.split(' ')[0]}
        </p>

        <div className="final-comparison">
          <div className="comparison-item">
            <div className="comparison-label">Facture initiale</div>
            <div className="comparison-amount old">{state.initialBill.toLocaleString('fr-FR')} €/an</div>
          </div>
          <div className="comparison-arrow">↓</div>
          <div className="comparison-item">
            <div className="comparison-label">Avec Starvolt</div>
            <div className="comparison-amount new">{state.bill.toLocaleString('fr-FR')} €/an</div>
          </div>
        </div>

        {savings > 0 && (
          <div className="final-total">
            <div className="total-label">Économies totales</div>
            <div className="total-amount">{savings.toLocaleString('fr-FR')} €<span style={{ fontSize: 22, fontWeight: 600 }}>/an</span></div>
          </div>
        )}

        {state.bravoItems.length > 0 && (
          <div className="final-items">
            {state.bravoItems.map((item, i) => (
              <div key={i} className="final-item">
                <span className="final-item-check">✓</span>
                <span>{item}</span>
              </div>
            ))}
          </div>
        )}

        <div className="final-message">
          "Ceci n'est qu'une simulation, mais bientôt, tout sera réel."
        </div>

        <div style={{ marginTop: 20 }}>
          <button className="btn btn-secondary" onClick={onRestart}>
            🔄 Recommencer la simulation
          </button>
        </div>
      </div>
    </div>
  );
}

// ─────────────────────────────────────────────
// MAIN APP — State machine
// ─────────────────────────────────────────────

const INITIAL_STATE = {
  screen: 'WELCOME',
  name: 'Marie Dupont',
  city: 'Lyon',
  initialBill: 2000,
  bill: 2000,
  bravoItems: [],
};

export default function App() {
  const [appState, setAppState] = useState(INITIAL_STATE);
  const [history,  setHistory]  = useState([]);

  const goTo = useCallback((screen, updates = {}) => {
    setHistory(h => [...h, appState]);
    setAppState(s => ({ ...s, screen, ...updates }));
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }, [appState]);

  const goBack = useCallback(() => {
    if (history.length === 0) return;
    const prev = history[history.length - 1];
    setHistory(h => h.slice(0, -1));
    setAppState(prev);
    window.scrollTo({ top: 0, behavior: 'smooth' });
  }, [history]);

  const { screen } = appState;

  const renderScreen = () => {
    switch (screen) {

      case 'WELCOME':
        return (
          <WelcomeScreen
            state={appState}
            onStart={({ name, city, bill }) =>
              goTo('ADDRESS', { name, city, initialBill: bill, bill, bravoItems: [] })
            }
          />
        );

      case 'ADDRESS':
        return (
          <AddressScreen
            state={appState}
            onHasACC={() => goTo('ACC_MAP', { hasACC: true })}
            onNoACC={()   => goTo('NO_ACC',  { hasACC: false })}
            onBack={goBack}
          />
        );

      case 'ACC_MAP':
        return (
          <ACCMapScreen
            state={appState}
            onContinue={() => goTo('ACC_TARIFF')}
            onBack={goBack}
          />
        );

      case 'ACC_TARIFF':
        return (
          <ACCTariffScreen
            state={appState}
            onYes={() => goTo('BRAVO_1', {
              bill: appState.bill - 185,
              bravoItems: [...appState.bravoItems, 'Tarif ACC : −185 €/an'],
            })}
            onNo={() => goTo('NOT_INTERESTED')}
            onBack={goBack}
          />
        );

      case 'NOT_INTERESTED':
        return (
          <NotInterestedScreen
            state={appState}
            onContinue={() => goTo('COMWATT')}
            onBack={goBack}
          />
        );

      case 'NO_ACC':
        return (
          <NoACCScreen
            state={appState}
            onContinue={() => goTo('SOLAR')}
            onBack={goBack}
          />
        );

      case 'BRAVO_1':
        return (
          <BravoScreen
            state={appState}
            stepNumber={1}
            saving={185}
            label="Grâce au tarif ACC"
            onContinue={() => goTo('COMWATT')}
            onBack={goBack}
          />
        );

      case 'COMWATT':
        return (
          <ComwattScreen
            state={appState}
            onYes={() => goTo('BRAVO_2', {
              bill: appState.bill - 200,
              bravoItems: [...appState.bravoItems, 'Box Comwatt : −200 €/an'],
            })}
            onNo={() => goTo('SOLAR')}
            onBack={goBack}
          />
        );

      case 'BRAVO_2':
        return (
          <BravoScreen
            state={appState}
            stepNumber={2}
            saving={200}
            label="Grâce à la box Comwatt"
            onContinue={() => goTo('SOLAR')}
            onBack={goBack}
          />
        );

      case 'SOLAR':
        return (
          <SolarScreen
            state={appState}
            onYes={() => goTo('BRAVO_3', {
              bill: appState.bill - 1000,
              bravoItems: [...appState.bravoItems, 'Solaire + batterie : −1 000 €/an'],
            })}
            onNo={() => goTo('FINAL')}
            onBack={goBack}
          />
        );

      case 'BRAVO_3':
        return (
          <BravoScreen
            state={appState}
            stepNumber={3}
            saving={1000}
            label="Grâce aux panneaux solaires"
            onContinue={() => goTo('FINAL')}
            onBack={goBack}
          />
        );

      case 'FINAL':
        return (
          <FinalScreen
            state={appState}
            onRestart={() => {
              setHistory([]);
              setAppState(INITIAL_STATE);
            }}
          />
        );

      default:
        return null;
    }
  };

  return (
    <div className="app">
      {/* Decorative chevrons (right side) */}
      <div className="chevrons-deco" aria-hidden="true">
        {['»', '»', '»', '»'].map((c, i) => (
          <span key={i}>{c}</span>
        ))}
      </div>

      {renderScreen()}

      {/* Fixed logo */}
      <div className="logo-fixed">
        <Logo width={130} />
      </div>
    </div>
  );
}
