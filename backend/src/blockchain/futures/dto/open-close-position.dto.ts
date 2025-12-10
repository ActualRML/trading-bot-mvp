export class OpenPositionDto {
  asset: string; // bytes32 asset symbol, e.g., "BTC"
  size: string; // size in wei
  isLong: boolean;
  collateralToken: string;
  collateralAmount: string; // in wei
}

export class ClosePositionDto {
  positionId: string;
  collateralToken: string;
  collateralAmount: string;
}
