import InventoryGrid from './InventoryGrid';
import CraftingUI from './CraftingUI';
import { useAppSelector } from '../../store';
import { selectRightInventory } from '../../store/inventory';

const RightInventory: React.FC = () => {
  const rightInventory = useAppSelector(selectRightInventory);

  if (rightInventory.type === 'crafting') {
    return <CraftingUI inventory={rightInventory} />;
  }

  return <InventoryGrid inventory={rightInventory} />;
};

export default RightInventory;
