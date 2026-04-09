import { Inventory, SlotWithItem } from '../../typings';
import React, { Fragment, useMemo } from 'react';
import { Items } from '../../store/items';
import { Locale } from '../../store/locale';
import ReactMarkdown from 'react-markdown';
import { useAppSelector } from '../../store';
import ClockIcon from '../utils/icons/ClockIcon';
import { getItemUrl } from '../../helpers';
import { Paper, Text, Divider } from '@mantine/core';
import { tokens } from '../../theme';

const SlotTooltip: React.ForwardRefRenderFunction<
  HTMLDivElement,
  { item: SlotWithItem; inventoryType: Inventory['type']; style: React.CSSProperties }
> = ({ item, inventoryType, style }, ref) => {
  const additionalMetadata = useAppSelector((state) => state.inventory.additionalMetadata);
  const itemData = useMemo(() => Items[item.name], [item]);
  const ingredients = useMemo(() => {
    if (!item.ingredients) return null;
    return Object.entries(item.ingredients).sort((a, b) => a[1] - b[1]);
  }, [item]);
  const description = item.metadata?.description || itemData?.description;
  const ammoName = itemData?.ammoName && Items[itemData?.ammoName]?.label;

  return (
    <>
      {!itemData ? (
        <Paper
          ref={ref}
          style={{
            ...style,
            pointerEvents: 'none',
            border: `1px solid ${tokens.borderTeal}`,
            minWidth: 200,
            width: 200,
            zIndex: 9999,
          }}
          p="xs"
        >
          <Text ff="'Orbitron', sans-serif" size="sm" c="white">{item.name}</Text>
          <Divider color={tokens.borderTeal} my={6} />
        </Paper>
      ) : (
        <Paper
          ref={ref}
          style={{
            ...style,
            pointerEvents: 'none',
            border: `1px solid ${tokens.borderTeal}`,
            minWidth: 200,
            width: 200,
            zIndex: 9999,
          }}
          p="xs"
        >
          <div className="tooltip-header-wrapper">
            <Text ff="'Orbitron', sans-serif" size="sm" c="white" fw={500}>
              {item.metadata?.label || itemData.label || item.name}
            </Text>
            {inventoryType === 'crafting' ? (
              <div className="tooltip-crafting-duration">
                <ClockIcon />
                <Text size="xs" c={tokens.textSecondary} ff="'Rajdhani', sans-serif">
                  {(item.duration !== undefined ? item.duration : 3000) / 1000}s
                </Text>
              </div>
            ) : (
              <Text size="xs" c={tokens.textMuted} ff="'Rajdhani', sans-serif">
                {item.metadata?.type}
              </Text>
            )}
          </div>
          <Divider color={tokens.borderTeal} my={6} />
          {description && (
            <div className="tooltip-description">
              <ReactMarkdown className="tooltip-markdown">{description}</ReactMarkdown>
            </div>
          )}
          {inventoryType !== 'crafting' ? (
            <>
              {item.durability !== undefined && (
                <Text size="xs" ff="'Rajdhani', sans-serif" c={tokens.textSecondary}>
                  {Locale.ui_durability}: {Math.trunc(item.durability)}
                </Text>
              )}
              {item.metadata?.ammo !== undefined && (
                <Text size="xs" ff="'Rajdhani', sans-serif" c={tokens.textSecondary}>
                  {Locale.ui_ammo}: {item.metadata.ammo}
                </Text>
              )}
              {ammoName && (
                <Text size="xs" ff="'Rajdhani', sans-serif" c={tokens.textSecondary}>
                  {Locale.ammo_type}: {ammoName}
                </Text>
              )}
              {item.metadata?.serial && (
                <Text size="xs" ff="'Rajdhani', sans-serif" c={tokens.textSecondary}>
                  {Locale.ui_serial}: {item.metadata.serial}
                </Text>
              )}
              {item.metadata?.components && item.metadata?.components[0] && (
                <Text size="xs" ff="'Rajdhani', sans-serif" c={tokens.textSecondary}>
                  {Locale.ui_components}:{' '}
                  {(item.metadata?.components).map((component: string, index: number, array: []) =>
                    index + 1 === array.length ? Items[component]?.label : Items[component]?.label + ', '
                  )}
                </Text>
              )}
              {item.metadata?.weapontint && (
                <Text size="xs" ff="'Rajdhani', sans-serif" c={tokens.textSecondary}>
                  {Locale.ui_tint}: {item.metadata.weapontint}
                </Text>
              )}
              {additionalMetadata.map((data: { metadata: string; value: string }, index: number) => (
                <Fragment key={`metadata-${index}`}>
                  {item.metadata && item.metadata[data.metadata] && (
                    <Text size="xs" ff="'Rajdhani', sans-serif" c={tokens.textSecondary}>
                      {data.value}: {item.metadata[data.metadata]}
                    </Text>
                  )}
                </Fragment>
              ))}
              {item.metadata &&
                Object.entries(item.metadata)
                  .filter(([key, val]) =>
                    typeof val !== 'object' &&
                    val !== null &&
                    val !== undefined &&
                    !['description', 'label', 'type', 'ammo', 'serial', 'components', 'weapontint', 'container', 'durability', 'degrade'].includes(key) &&
                    !additionalMetadata.find((d) => d.metadata === key)
                  )
                  .map(([key, val]) => {
                    const label = key.replace(/([A-Z][a-z]+|[A-Z]+(?=[A-Z]|$))/g, ' $1').trim();
                    return (
                      <Text key={`dyn-${key}`} size="xs" ff="'Rajdhani', sans-serif" c={tokens.textSecondary}>
                        {label}: {String(val)}
                      </Text>
                    );
                  })}
            </>
          ) : (
            <div className="tooltip-ingredients">
              {ingredients &&
                ingredients.map((ingredient) => {
                  const [ingredientItem, count] = [ingredient[0], ingredient[1]];
                  return (
                    <div className="tooltip-ingredient" key={`ingredient-${ingredientItem}`}>
                      <img src={ingredientItem ? getItemUrl(ingredientItem) : 'none'} alt="item-image" />
                      <Text size="xs" ff="'Rajdhani', sans-serif" c={tokens.textSecondary}>
                        {count >= 1
                          ? `${count}x ${Items[ingredientItem]?.label || ingredientItem}`
                          : count === 0
                          ? `${Items[ingredientItem]?.label || ingredientItem}`
                          : `${count * 100}% ${Items[ingredientItem]?.label || ingredientItem}`}
                      </Text>
                    </div>
                  );
                })}
            </div>
          )}
        </Paper>
      )}
    </>
  );
};

export default React.forwardRef(SlotTooltip);
