<script setup lang="ts">
/**
 * Campo de importe en bolivianos.
 *
 * Envuelve a `UInputNumber` para que todos los montos de la aplicación se
 * escriban y se lean igual: dos decimales, separador del idioma y sin los
 * botones nativos del navegador.
 */
withDefaults(
  defineProps<{
    /** Importe en bolivianos. */
    modelValue: number | null
    /** Mínimo admitido. */
    min?: number
    /** Máximo admitido. */
    max?: number
    /** Texto de ayuda del campo vacío. */
    placeholder?: string
    /** Exige un valor para enviar el formulario. */
    required?: boolean
  }>(),
  { min: 0.01, max: 9_999_999.99, placeholder: undefined, required: false },
)

const emit = defineEmits<{
  'update:modelValue': [valor: number | null]
}>()

const { idioma } = useTexto()
const local = computed(() => (idioma.value === 'en' ? 'en-US' : 'es-BO'))
</script>

<template>
  <UInputNumber
    :model-value="modelValue"
    :min="min"
    :max="max"
    :step="0.01"
    :locale="local"
    :format-options="{
      style: 'currency',
      currency: 'BOB',
      currencyDisplay: 'symbol',
      minimumFractionDigits: 2,
      maximumFractionDigits: 2,
    }"
    :increment="false"
    :decrement="false"
    :placeholder="placeholder"
    :required="required"
    class="w-full"
    @update:model-value="
      (valor) => emit('update:modelValue', typeof valor === 'number' ? valor : null)
    "
  />
</template>
