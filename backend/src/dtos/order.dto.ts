export interface CreateOrderDto {
  customerName: string;
  phone: string;
  address: string;
  landmark?: string;
  notes?: string;
  items: Array<{
    menuItemId: string;
    quantity: number;
  }>;
  latitude: number;
  longitude: number;
}
