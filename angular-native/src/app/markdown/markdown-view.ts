import { Component, computed, input, output } from '@angular/core';
import { Pressable, Text, View } from '@ng-native/components';
import { parseMarkdown } from './markdown-model.ts';

/** Renders the supported markdown subset (spec §4) with native text and views. */
@Component({
  selector: 'app-markdown-view',
  imports: [Pressable, Text, View],
  template: `
    @for (block of blocks(); track $index) {
      @if (block.kind === 'heading') {
        <text
          accessibilityRole="header"
          [class.h1]="block.level === 1"
          [class.h2]="block.level === 2"
          [class.h3]="block.level === 3"
          [class.first]="$first"
        >
          @for (run of block.runs; track $index) {
            <text [class.italic]="run.italic" [class.code]="run.code" [class.tag]="run.tag">{{ run.text }}</text>
          }
        </text>
      } @else if (block.kind === 'paragraph') {
        <text class="p">
          @for (run of block.runs; track $index) {
            <text [class.bold]="run.bold" [class.italic]="run.italic" [class.code]="run.code" [class.tag]="run.tag">{{ run.text }}</text>
          }
        </text>
      } @else if (block.kind === 'list') {
        <view class="list">
          @for (item of block.items; track $index) {
            <view class="item">
              <text class="marker" [class.ordered]="block.ordered">{{ item.marker }}</text>
              <text class="item-text">
                @for (run of item.runs; track $index) {
                  <text [class.bold]="run.bold" [class.italic]="run.italic" [class.code]="run.code" [class.tag]="run.tag">{{ run.text }}</text>
                }
              </text>
            </view>
          }
        </view>
      } @else if (block.kind === 'tasks') {
        <view class="tasks">
          @for (task of block.items; track task.index) {
            <pressable
              class="task"
              [testID]="'task-' + task.index"
              accessibilityRole="button"
              [accessibilityLabel]="task.label"
              [accessibilityValue]="{ text: task.checked ? 'checked' : 'unchecked' }"
              (press)="toggleTask.emit(task.index)"
            >
              <view class="box" [class.box-on]="task.checked">
                @if (task.checked) {
                  <text class="check">✓</text>
                }
              </view>
              <text class="task-text" [class.task-done]="task.checked">
                @for (run of task.runs; track $index) {
                  <text [class.bold]="run.bold" [class.italic]="run.italic" [class.code]="run.code" [class.tag]="run.tag">{{ run.text }}</text>
                }
              </text>
            </pressable>
          }
        </view>
      } @else if (block.kind === 'quote') {
        <view class="quote">
          <view class="bar"></view>
          <text class="quote-text">
            @for (run of block.runs; track $index) {
              <text [class.bold]="run.bold" [class.code]="run.code" [class.tag]="run.tag">{{ run.text }}</text>
            }
          </text>
        </view>
      } @else if (block.kind === 'code') {
        <view class="codeblock">
          <text class="codeblock-text">{{ block.text }}</text>
        </view>
      }
    }
  `,
  styles: `
    .p,
    .item-text,
    .marker {
      font-size: 17px;
      line-height: 24px;
      color: var(--text);
    }
    .p {
      margin-bottom: 12px;
    }
    .h1 {
      font-size: 28px;
      line-height: 34px;
      font-weight: 700;
      color: var(--text);
      margin-bottom: 12px;
    }
    .h2 {
      font-size: 22px;
      line-height: 28px;
      font-weight: 700;
      color: var(--text);
      margin-top: 16px;
      margin-bottom: 8px;
    }
    .h3 {
      font-size: 18px;
      line-height: 24px;
      font-weight: 600;
      color: var(--text);
      margin-top: 12px;
      margin-bottom: 6px;
    }
    .first {
      margin-top: 0;
    }
    .bold {
      font-weight: 700;
    }
    .italic {
      font-style: italic;
    }
    .code {
      font-family: var(--mono, Menlo);
      font-size: 15px;
      color: var(--accent);
      background-color: var(--accent-soft);
    }
    .tag {
      color: var(--accent);
      font-weight: 500;
    }
    .tasks {
      margin-bottom: 12px;
      gap: 8px;
    }
    .task {
      flex-direction: row;
      align-items: flex-start;
      gap: 10px;
    }
    .box {
      width: 22px;
      height: 22px;
      margin-top: 1px;
      border-radius: 6px;
      border-width: 2px;
      border-color: var(--text-tertiary);
      align-items: center;
      justify-content: center;
    }
    .box-on {
      border-width: 0;
      background-color: var(--accent);
    }
    .check {
      font-size: 14px;
      line-height: 18px;
      font-weight: 700;
      color: #ffffff;
    }
    .task-text {
      flex: 1;
      font-size: 17px;
      line-height: 24px;
      color: var(--text);
    }
    .task-done {
      color: var(--text-tertiary);
      text-decoration-line: line-through;
    }
    .list {
      margin-bottom: 12px;
      gap: 4px;
    }
    .item {
      flex-direction: row;
      gap: 8px;
    }
    .marker {
      min-width: 8px;
    }
    .ordered {
      min-width: 18px;
    }
    .item-text {
      flex: 1;
    }
    .quote {
      flex-direction: row;
      gap: 12px;
      margin-bottom: 12px;
    }
    .bar {
      width: 3px;
      background-color: var(--accent);
    }
    .quote-text {
      flex: 1;
      font-size: 17px;
      line-height: 24px;
      font-style: italic;
      color: var(--text-secondary);
    }
    .codeblock {
      background-color: var(--code-bg);
      border-radius: 10px;
      padding: 12px;
      margin-bottom: 12px;
    }
    .codeblock-text {
      font-family: var(--mono, Menlo);
      font-size: 14px;
      line-height: 20px;
      color: var(--code-text);
    }
  `,
})
export class MarkdownView {
  readonly source = input.required<string>();
  /** Emits the document-order index of a tapped task. */
  readonly toggleTask = output<number>();
  protected readonly blocks = computed(() => parseMarkdown(this.source()));
}
