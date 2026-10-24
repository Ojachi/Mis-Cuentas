import { currency } from '@micu/domain';

export function App() {
  return (
    <>
      <header className="business-header">
        <strong>Perros al paso</strong>
        <span>Base de desarrollo</span>
      </header>
      <main>
        <p className="section-label">Cuentas del negocio</p>
        <h1>Registro del negocio</h1>
        <section className="notice" aria-labelledby="development-title">
          <h2 id="development-title">Estamos preparando el registro diario</h2>
          <p>
            Ventas, compras y gastos del negocio, separados de aportes y
            retiros.
          </p>
          <p>Moneda del negocio: {currency}</p>
          <p className="development-limit">
            Esta versión todavía no guarda movimientos ni funciona sin conexión.
          </p>
        </section>
      </main>
    </>
  );
}
